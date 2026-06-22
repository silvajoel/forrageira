<?php
declare(strict_types=1);

final class NotificationsController
{
    /**
     * GET /notifications?scope=user|admin&limit=
     *  - scope=user (padrao): notificacoes do proprio usuario
     *  - scope=admin: notificacoes de papel admin (exige role admin)
     */
    public static function index(): void
    {
        $ctx = Auth::requireUser();
        $scope = isset($_GET['scope']) ? (string) $_GET['scope'] : 'user';
        $limit = self::limit($_GET['limit'] ?? null, 50);

        if ($scope === 'admin') {
            if ($ctx->profile === null || !$ctx->isAdmin()) {
                Response::error('Acesso restrito a administradores.', 403);
            }
            $rows = Db::all(
                "SELECT * FROM app_notifications
                 WHERE recipient_type = 'role' AND recipient_id = 'admin'
                 ORDER BY created_at DESC LIMIT $limit"
            );
        } else {
            $rows = Db::all(
                "SELECT * FROM app_notifications
                 WHERE recipient_type = 'user' AND recipient_id = ?
                 ORDER BY created_at DESC LIMIT $limit",
                [$ctx->uid]
            );
        }
        Response::success('Notificacoes.', array_map([self::class, 'serialize'], $rows));
    }

    /** PATCH /notifications/{id}/read */
    public static function markRead(array $params): void
    {
        $ctx = Auth::requireUser();
        $id = $params['id'];
        $n = Db::first('SELECT * FROM app_notifications WHERE id = ?', [$id]);
        if ($n === null) {
            Response::error('Notificacao nao encontrada.', 404);
        }
        if (!self::canAccess($ctx, $n)) {
            Response::error('Acesso negado.', 403);
        }
        Db::run('UPDATE app_notifications SET read_status = 1 WHERE id = ?', [$id]);
        Response::success('Notificacao marcada como lida.');
    }

    /** POST /notifications/read-all { includeAdminRole?: bool } */
    public static function markAllRead(): void
    {
        $ctx = Auth::requireUser();
        $includeAdmin = Json::optBool(Json::body(), 'includeAdminRole', false);

        Db::run(
            "UPDATE app_notifications SET read_status = 1
             WHERE recipient_type = 'user' AND recipient_id = ? AND read_status = 0",
            [$ctx->uid]
        );

        if ($includeAdmin && $ctx->profile && $ctx->isAdmin()) {
            Db::run(
                "UPDATE app_notifications SET read_status = 1
                 WHERE recipient_type = 'role' AND recipient_id = 'admin' AND read_status = 0"
            );
        }
        Response::success('Notificacoes marcadas como lidas.');
    }

    private static function canAccess(AuthContext $ctx, array $n): bool
    {
        if ($n['recipient_type'] === 'user') {
            return $n['recipient_id'] === $ctx->uid;
        }
        if ($n['recipient_type'] === 'role') {
            return $n['recipient_id'] === 'admin' && $ctx->profile && $ctx->isAdmin();
        }
        return false;
    }

    public static function serialize(array $row): array
    {
        return [
            'id'             => $row['id'],
            'title'          => $row['title'],
            'message'        => $row['message'],
            'recipient_type' => $row['recipient_type'],
            'recipient_id'   => $row['recipient_id'],
            'analysis_id'    => $row['analysis_id'] ?? null,
            'read'           => (int) $row['read_status'] === 1,
            'created_at'     => self::iso($row['created_at'] ?? null),
        ];
    }

    private static function limit($raw, int $default): int
    {
        $n = is_numeric($raw) ? (int) $raw : $default;
        return max(1, min($n, 200));
    }

    private static function iso(?string $dt): ?string
    {
        return ($dt === null || $dt === '') ? null : str_replace(' ', 'T', $dt) . 'Z';
    }
}
