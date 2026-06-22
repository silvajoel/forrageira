<?php
declare(strict_types=1);

final class AnalysisController
{
    /**
     * POST /analysis
     * Corpo: { name, notes, latitude, longitude, imageUrls: [] }
     * O user_id vem do token. Insere a analise + imagens e notifica os admins.
     */
    public static function create(): void
    {
        $ctx = Auth::requireUser();
        if ($ctx->profile === null) {
            // FK exige a linha em users; sincroniza on-the-fly.
            Db::run(
                'INSERT INTO users (id, name, email, role, active, created_at) VALUES (?, ?, ?, ?, 1, ?)',
                [$ctx->uid, $ctx->name ?? '', $ctx->email ?? '', 'user', Ids::now()]
            );
        }

        $body = Json::body();
        $name  = Json::requireString($body, 'name');
        $notes = Json::optString($body, 'notes', '') ?? '';
        $lat   = Json::optFloat($body, 'latitude');
        $lng   = Json::optFloat($body, 'longitude');
        $imageUrls = self::imageUrls($body);

        $id = Ids::generate();
        $pdo = Db::pdo();
        $pdo->beginTransaction();
        try {
            Db::run(
                'INSERT INTO analysis_requests
                    (id, user_id, name, notes, status, latitude, longitude, created_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                [$id, $ctx->uid, $name, $notes, 'pending', $lat, $lng, Ids::now()]
            );
            foreach ($imageUrls as $order => $url) {
                Db::run(
                    'INSERT INTO analysis_request_images (analysis_request_id, image_url, image_order)
                     VALUES (?, ?, ?)',
                    [$id, $url, $order]
                );
            }
            $pdo->commit();
        } catch (Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        try {
            Notifier::adminsNewAnalysis($id, $name, $ctx->uid);
        } catch (Throwable $e) {
            error_log('[forrageira] notificar admins falhou: ' . $e->getMessage());
        }

        Response::success('Analise criada.', self::find($id), 201);
    }

    /**
     * GET /analysis?user_id=&limit=
     * Sem user_id: somente admin (lista todas). Com user_id: o proprio usuario ou admin.
     */
    public static function index(): void
    {
        $ctx = Auth::requireUser();
        $userId = isset($_GET['user_id']) ? (string) $_GET['user_id'] : null;
        $limit  = self::limit($_GET['limit'] ?? null, 100);

        if ($userId === null) {
            // listar todas -> admin
            if ($ctx->profile === null || !$ctx->isAdmin()) {
                Response::error('Acesso restrito a administradores.', 403);
            }
            $rows = Db::all(
                'SELECT * FROM analysis_requests ORDER BY created_at DESC LIMIT ' . $limit
            );
        } else {
            if ($userId !== $ctx->uid && !($ctx->profile && $ctx->isAdmin())) {
                Response::error('Acesso negado.', 403);
            }
            $rows = Db::all(
                'SELECT * FROM analysis_requests WHERE user_id = ? ORDER BY created_at DESC LIMIT ' . $limit,
                [$userId]
            );
        }

        $images = self::imagesByRequest(array_column($rows, 'id'));
        $out = array_map(fn($r) => self::serialize($r, $images[$r['id']] ?? []), $rows);
        Response::success('Analises.', $out);
    }

    /** GET /analysis/{id} */
    public static function show(array $params): void
    {
        $ctx = Auth::requireUser();
        $row = Db::first('SELECT * FROM analysis_requests WHERE id = ?', [$params['id']]);
        if ($row === null) {
            Response::error('Analise nao encontrada.', 404);
        }
        if ($row['user_id'] !== $ctx->uid && !($ctx->profile && $ctx->isAdmin())) {
            Response::error('Acesso negado.', 403);
        }
        Response::success('Analise.', self::find($params['id']));
    }

    /**
     * POST /analysis/{id}/finalize  (admin)
     * Corpo: { species_name, care_instructions, admin_notes }
     */
    public static function finalize(array $params): void
    {
        $ctx = Auth::requireAdmin();
        $id = $params['id'];
        $row = Db::first('SELECT * FROM analysis_requests WHERE id = ?', [$id]);
        if ($row === null) {
            Response::error('Analise nao encontrada.', 404);
        }
        $body = Json::body();
        $species = Json::requireString($body, 'species_name');
        $care    = Json::optString($body, 'care_instructions', '') ?? '';
        $notes   = Json::optString($body, 'admin_notes', '') ?? '';

        Db::run(
            'UPDATE analysis_requests
                SET status = ?, species_name = ?, care_instructions = ?, admin_notes = ?,
                    reviewed_at = ?, reviewed_by = ?
              WHERE id = ?',
            ['completed', $species, $care, $notes, Ids::now(), $ctx->uid, $id]
        );

        try {
            Notifier::userAnalysisCompleted($id, (string) $row['user_id'], (string) $row['name']);
        } catch (Throwable $e) {
            error_log('[forrageira] notificar usuario falhou: ' . $e->getMessage());
        }

        self::auditLog($ctx, 'Finalizou analise', $id, [
            'species_name' => $species,
            'user_id'      => $row['user_id'],
        ]);

        Response::success('Analise finalizada.', self::find($id));
    }

    /**
     * POST /analysis/{id}/reopen  (admin)
     * Corpo: { reason? }
     */
    public static function reopen(array $params): void
    {
        $ctx = Auth::requireAdmin();
        $id = $params['id'];
        $row = Db::first('SELECT * FROM analysis_requests WHERE id = ?', [$id]);
        if ($row === null) {
            Response::error('Analise nao encontrada.', 404);
        }
        $reason = Json::optString(Json::body(), 'reason', '') ?? '';

        Db::run(
            'UPDATE analysis_requests SET status = ?, reviewed_at = NULL, reviewed_by = NULL WHERE id = ?',
            ['pending', $id]
        );

        try {
            Notifier::userAnalysisReopened($id, (string) $row['user_id'], (string) $row['name'], $reason);
        } catch (Throwable $e) {
            error_log('[forrageira] notificar reabertura falhou: ' . $e->getMessage());
        }

        self::auditLog($ctx, 'Reabriu analise', $id, ['user_id' => $row['user_id']]);
        Response::success('Analise reaberta.', self::find($id));
    }

    // ---------- helpers ----------

    /** @param array<string,string> $meta */
    private static function auditLog(AuthContext $ctx, string $action, string $targetId, array $meta): void
    {
        Db::run(
            'INSERT INTO admin_audit_logs (id, action, actor_email, actor_uid, target_id, metadata, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)',
            [Ids::generate(), $action, $ctx->email, $ctx->uid, $targetId, json_encode($meta), Ids::now()]
        );
    }

    private static function find(string $id): array
    {
        $row = Db::first('SELECT * FROM analysis_requests WHERE id = ?', [$id]);
        $imgs = self::imagesByRequest([$id])[$id] ?? [];
        return self::serialize($row, $imgs);
    }

    /** @return array<string,string[]> map request_id -> [urls] (ordenadas) */
    private static function imagesByRequest(array $ids): array
    {
        $ids = array_values(array_filter($ids));
        if ($ids === []) {
            return [];
        }
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $rows = Db::all(
            "SELECT analysis_request_id, image_url FROM analysis_request_images
             WHERE analysis_request_id IN ($placeholders)
             ORDER BY image_order ASC, id ASC",
            $ids
        );
        $map = [];
        foreach ($rows as $r) {
            $map[$r['analysis_request_id']][] = $r['image_url'];
        }
        return $map;
    }

    private static function serialize(array $row, array $imageUrls): array
    {
        return [
            'id'                => $row['id'],
            'user_id'           => $row['user_id'],
            'name'              => $row['name'],
            'notes'             => $row['notes'] ?? '',
            'status'            => $row['status'],
            'latitude'          => $row['latitude'] !== null ? (float) $row['latitude'] : 0.0,
            'longitude'         => $row['longitude'] !== null ? (float) $row['longitude'] : 0.0,
            'images'            => $imageUrls,
            'species_name'      => $row['species_name'] ?? null,
            'care_instructions' => $row['care_instructions'] ?? null,
            'admin_notes'       => $row['admin_notes'] ?? null,
            'created_at'        => self::iso($row['created_at'] ?? null),
            'reviewed_at'       => self::iso($row['reviewed_at'] ?? null),
        ];
    }

    /** @return string[] */
    private static function imageUrls(array $body): array
    {
        $urls = $body['imageUrls'] ?? $body['images'] ?? [];
        if (!is_array($urls)) {
            return [];
        }
        return array_values(array_filter(array_map(
            fn($u) => is_string($u) ? trim($u) : '',
            $urls
        )));
    }

    private static function limit($raw, int $default): int
    {
        $n = is_numeric($raw) ? (int) $raw : $default;
        return max(1, min($n, 500));
    }

    private static function iso(?string $dt): ?string
    {
        if ($dt === null || $dt === '') {
            return null;
        }
        return str_replace(' ', 'T', $dt) . 'Z';
    }
}
