<?php
declare(strict_types=1);

final class AuditController
{
    /** GET /audit-logs?limit=  (admin) */
    public static function index(): void
    {
        Auth::requireAdmin();
        $limit = self::limit($_GET['limit'] ?? null, 30);
        $rows = Db::all("SELECT * FROM admin_audit_logs ORDER BY created_at DESC LIMIT $limit");
        Response::success('Logs.', array_map([self::class, 'serialize'], $rows));
    }

    /** POST /audit-logs  (admin)  { action, target_id?, metadata?{} } */
    public static function create(): void
    {
        $ctx = Auth::requireAdmin();
        $body = Json::body();
        $action = Json::requireString($body, 'action');
        $targetId = Json::optString($body, 'target_id');
        $metadata = (isset($body['metadata']) && is_array($body['metadata']))
            ? $body['metadata'] : [];

        Db::run(
            'INSERT INTO admin_audit_logs (id, action, actor_email, actor_uid, target_id, metadata, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)',
            [Ids::generate(), $action, $ctx->email, $ctx->uid, $targetId, json_encode($metadata), Ids::now()]
        );
        Response::success('Log registrado.', [], 201);
    }

    private static function serialize(array $row): array
    {
        $meta = null;
        if (!empty($row['metadata'])) {
            $decoded = json_decode((string) $row['metadata'], true);
            $meta = is_array($decoded) ? $decoded : null;
        }
        return [
            'id'          => $row['id'],
            'action'      => $row['action'],
            'actor_email' => $row['actor_email'] ?? null,
            'actor_uid'   => $row['actor_uid'] ?? null,
            'target_id'   => $row['target_id'] ?? null,
            'metadata'    => $meta ?? [],
            'created_at'  => ($row['created_at'] ?? null)
                ? str_replace(' ', 'T', $row['created_at']) . 'Z'
                : null,
        ];
    }

    private static function limit($raw, int $default): int
    {
        $n = is_numeric($raw) ? (int) $raw : $default;
        return max(1, min($n, 200));
    }
}
