<?php
declare(strict_types=1);

/**
 * Cria notificacoes in-app (tabela app_notifications) e dispara o push (FCM)
 * para os destinatarios. Reproduz o comportamento do AppNotificationService
 * + as mensagens do Firestore original.
 */
final class Notifier
{
    /** Notifica todos os admins ativos sobre uma nova analise. */
    public static function adminsNewAnalysis(string $analysisId, string $forageName, string $requesterId): void
    {
        $title = 'Nova analise cadastrada';
        $message = "Uma nova forrageira \"$forageName\" foi enviada para analise.";

        // Uma notificacao de papel (recipient_type=role, recipient_id=admin) para o sino.
        self::insert([
            'recipient_type' => 'role',
            'recipient_id'   => 'admin',
            'analysis_id'    => $analysisId,
            'requester_id'   => $requesterId,
            'title'          => $title,
            'message'        => $message,
        ]);

        // Push para cada admin ativo com token.
        $tokens = self::tokensForAdmins();
        self::push($tokens, $title, $message, $analysisId);
    }

    /** Notifica o dono da analise que ela foi concluida. */
    public static function userAnalysisCompleted(string $analysisId, string $userId, string $forageName): void
    {
        $title = 'Analise concluida';
        $message = "A analise da forrageira \"$forageName\" foi finalizada.";
        self::toUser($analysisId, $userId, $title, $message);
    }

    /** Notifica o dono que a analise foi reaberta para ajustes. */
    public static function userAnalysisReopened(string $analysisId, string $userId, string $forageName, string $reason): void
    {
        $reason = trim($reason);
        $title = 'Analise reaberta para ajustes';
        $message = $reason === ''
            ? "A analise da forrageira \"$forageName\" foi reaberta para ajustes."
            : "A analise da forrageira \"$forageName\" foi reaberta para ajustes. Motivo: $reason";
        self::toUser($analysisId, $userId, $title, $message);
    }

    private static function toUser(string $analysisId, string $userId, string $title, string $message): void
    {
        self::insert([
            'recipient_type' => 'user',
            'recipient_id'   => $userId,
            'analysis_id'    => $analysisId,
            'requester_id'   => null,
            'title'          => $title,
            'message'        => $message,
        ]);
        self::push(self::tokensForUser($userId), $title, $message, $analysisId);
    }

    private static function insert(array $n): void
    {
        Db::run(
            'INSERT INTO app_notifications
                (id, analysis_id, requester_id, recipient_id, recipient_type, title, message, read_status, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)',
            [
                Ids::generate(),
                $n['analysis_id'],
                $n['requester_id'],
                $n['recipient_id'],
                $n['recipient_type'],
                $n['title'],
                $n['message'],
                Ids::now(),
            ]
        );
    }

    private static function push(array $tokens, string $title, string $message, ?string $analysisId): void
    {
        if ($tokens === []) {
            return;
        }
        try {
            Fcm::sendToTokens(
                $tokens,
                $title,
                $message,
                $analysisId !== null ? ['analysis_id' => $analysisId] : []
            );
        } catch (Throwable $e) {
            error_log('[forrageira-notify] push falhou: ' . $e->getMessage());
        }
    }

    /** @return string[] */
    private static function tokensForAdmins(): array
    {
        $rows = Db::all(
            "SELECT fcmToken FROM users
             WHERE role = 'admin' AND active = 1 AND fcmToken IS NOT NULL AND fcmToken <> ''"
        );
        return array_column($rows, 'fcmToken');
    }

    /** @return string[] */
    private static function tokensForUser(string $userId): array
    {
        $row = Db::first(
            "SELECT fcmToken FROM users WHERE id = ? AND fcmToken IS NOT NULL AND fcmToken <> ''",
            [$userId]
        );
        return $row ? [$row['fcmToken']] : [];
    }
}
