<?php
declare(strict_types=1);

/**
 * Envio de push pela API FCM HTTP v1, autenticando com a service account do Firebase.
 *
 * Fluxo:
 *  - assina um JWT com a chave privada da service account
 *  - troca por um access_token OAuth2 (escopo firebase.messaging)
 *  - chama messages:send para cada token de dispositivo
 *
 * Falhas de envio NAO devem quebrar a requisicao principal: chamadas envolvidas
 * em try/catch pelos controllers.
 */
final class Fcm
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
    private const TOKEN_URI = 'https://oauth2.googleapis.com/token';

    /**
     * Envia uma notificacao para um ou mais tokens.
     * @param string[] $tokens
     * @param array<string,string> $data  payload de dados (ex.: analysis_id)
     */
    public static function sendToTokens(array $tokens, string $title, string $body, array $data = []): void
    {
        $tokens = array_values(array_filter(array_unique($tokens)));
        if ($tokens === []) {
            return;
        }

        $config = $GLOBALS['app_config'];
        $projectId = $config['firebase_project_id'];
        $accessToken = self::accessToken();
        if ($accessToken === null) {
            return; // sem credencial valida; segue sem push
        }

        $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

        foreach ($tokens as $token) {
            $message = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'data' => array_map('strval', $data),
                    'android' => ['priority' => 'high'],
                ],
            ];
            self::httpPostJson($url, json_encode($message), [
                'Authorization: Bearer ' . $accessToken,
                'Content-Type: application/json',
            ]);
        }
    }

    /** Obtem um access_token OAuth2, com cache curto em arquivo temporario. */
    private static function accessToken(): ?string
    {
        $cacheFile = sys_get_temp_dir() . '/forrageira_fcm_token.json';
        if (is_file($cacheFile)) {
            $c = json_decode((string) file_get_contents($cacheFile), true);
            if (is_array($c) && ($c['expires'] ?? 0) > time() + 60 && !empty($c['token'])) {
                return $c['token'];
            }
        }

        $sa = self::serviceAccount();
        if ($sa === null) {
            return null;
        }

        $now = time();
        $claims = [
            'iss'   => $sa['client_email'],
            'scope' => self::SCOPE,
            'aud'   => self::TOKEN_URI,
            'iat'   => $now,
            'exp'   => $now + 3600,
        ];

        $jwtHeader = self::b64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $jwtClaims = self::b64url(json_encode($claims));
        $signingInput = "$jwtHeader.$jwtClaims";

        $signature = '';
        $ok = openssl_sign($signingInput, $signature, $sa['private_key'], OPENSSL_ALGO_SHA256);
        if (!$ok) {
            error_log('[forrageira-fcm] falha ao assinar JWT da service account');
            return null;
        }
        $assertion = "$signingInput." . self::b64url($signature);

        $resp = self::httpPostForm(self::TOKEN_URI, [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $assertion,
        ]);
        $json = json_decode((string) $resp, true);
        if (!is_array($json) || empty($json['access_token'])) {
            error_log('[forrageira-fcm] resposta OAuth invalida: ' . substr((string) $resp, 0, 200));
            return null;
        }

        @file_put_contents($cacheFile, json_encode([
            'token'   => $json['access_token'],
            'expires' => time() + (int) ($json['expires_in'] ?? 3600),
        ]));

        return $json['access_token'];
    }

    private static function serviceAccount(): ?array
    {
        $path = $GLOBALS['app_config']['firebase_service_account'] ?? '';
        if ($path === '' || !is_file($path)) {
            error_log('[forrageira-fcm] service account nao encontrada: ' . $path);
            return null;
        }
        $json = json_decode((string) file_get_contents($path), true);
        if (!is_array($json) || empty($json['client_email']) || empty($json['private_key'])) {
            error_log('[forrageira-fcm] service account invalida');
            return null;
        }
        return $json;
    }

    private static function httpPostForm(string $url, array $fields): ?string
    {
        return self::httpPostRaw($url, http_build_query($fields), [
            'Content-Type: application/x-www-form-urlencoded',
        ]);
    }

    private static function httpPostJson(string $url, string $payload, array $headers): ?string
    {
        return self::httpPostRaw($url, $payload, $headers);
    }

    private static function httpPostRaw(string $url, string $payload, array $headers): ?string
    {
        if (function_exists('curl_init')) {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST           => true,
                CURLOPT_POSTFIELDS     => $payload,
                CURLOPT_HTTPHEADER     => $headers,
                CURLOPT_TIMEOUT        => 10,
                CURLOPT_SSL_VERIFYPEER => true,
            ]);
            $body = curl_exec($ch);
            if ($body === false) {
                error_log('[forrageira-fcm] curl: ' . curl_error($ch));
            }
            curl_close($ch);
            return $body === false ? null : $body;
        }

        $ctx = stream_context_create(['http' => [
            'method'        => 'POST',
            'header'        => implode("\r\n", $headers),
            'content'       => $payload,
            'timeout'       => 10,
            'ignore_errors' => true,
        ]]);
        $body = @file_get_contents($url, false, $ctx);
        return $body === false ? null : $body;
    }

    private static function b64url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
