<?php
declare(strict_types=1);

/**
 * Verifica um Firebase ID token (JWT RS256) sem depender do Composer.
 *
 * Passos:
 *  - le o header Authorization: Bearer <token>
 *  - valida assinatura RS256 com as chaves publicas do Google (x509), cacheadas
 *  - confere aud == project_id, iss == https://securetoken.google.com/<project_id>,
 *    exp/iat validos e sub (uid) presente
 *
 * Retorna o payload (claims) com pelo menos: sub (uid), email, name.
 */
final class FirebaseToken
{
    private const CERTS_URL =
        'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

    /** Extrai o token do header Authorization. Lanca ApiException se ausente. */
    public static function fromAuthHeader(): string
    {
        $header = self::authorizationHeader();
        if ($header === null || !preg_match('/^Bearer\s+(.+)$/i', $header, $m)) {
            throw new ApiException('Token de autenticacao ausente.', 401);
        }
        return trim($m[1]);
    }

    /** Verifica o token e retorna os claims. Lanca ApiException(401) se invalido. */
    public static function verify(string $jwt): array
    {
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) {
            throw new ApiException('Token malformado.', 401);
        }
        [$h64, $p64, $s64] = $parts;

        $header  = json_decode(self::b64urlDecode($h64), true);
        $payload = json_decode(self::b64urlDecode($p64), true);
        $sig     = self::b64urlDecode($s64);

        if (!is_array($header) || !is_array($payload)) {
            throw new ApiException('Token ilegivel.', 401);
        }
        if (($header['alg'] ?? '') !== 'RS256' || empty($header['kid'])) {
            throw new ApiException('Algoritmo do token nao suportado.', 401);
        }

        $cert = self::certForKid($header['kid']);
        if ($cert === null) {
            throw new ApiException('Chave do token nao encontrada.', 401);
        }

        $pubKey = openssl_pkey_get_public($cert);
        if ($pubKey === false) {
            throw new ApiException('Chave publica invalida.', 401);
        }
        $ok = openssl_verify("$h64.$p64", $sig, $pubKey, OPENSSL_ALGO_SHA256);
        if ($ok !== 1) {
            throw new ApiException('Assinatura do token invalida.', 401);
        }

        self::validateClaims($payload);
        return $payload;
    }

    private static function validateClaims(array $p): void
    {
        $projectId = $GLOBALS['app_config']['firebase_project_id'];
        $now = time();
        $leeway = 60; // tolerancia de relogio

        if (($p['aud'] ?? null) !== $projectId) {
            throw new ApiException('Token de outro projeto.', 401);
        }
        if (($p['iss'] ?? null) !== "https://securetoken.google.com/$projectId") {
            throw new ApiException('Emissor do token invalido.', 401);
        }
        if (!isset($p['exp']) || ($p['exp'] + $leeway) < $now) {
            throw new ApiException('Token expirado.', 401);
        }
        if (isset($p['iat']) && ($p['iat'] - $leeway) > $now) {
            throw new ApiException('Token ainda nao valido.', 401);
        }
        if (empty($p['sub'])) {
            throw new ApiException('Token sem identificacao de usuario.', 401);
        }
    }

    /** Retorna o certificado x509 (PEM) correspondente ao kid, usando cache. */
    private static function certForKid(string $kid): ?string
    {
        $certs = self::loadCerts();
        return $certs[$kid] ?? null;
    }

    /** Carrega o mapa kid=>cert das chaves publicas do Google, com cache em arquivo. */
    private static function loadCerts(): array
    {
        $cacheFile = sys_get_temp_dir() . '/forrageira_google_certs.json';

        if (is_file($cacheFile)) {
            $cached = json_decode((string) file_get_contents($cacheFile), true);
            if (is_array($cached) && ($cached['expires'] ?? 0) > time() && !empty($cached['certs'])) {
                return $cached['certs'];
            }
        }

        [$body, $maxAge] = self::httpGetWithMaxAge(self::CERTS_URL);
        $certs = json_decode($body, true);
        if (!is_array($certs) || $certs === []) {
            // fallback para cache antigo se o fetch falhar
            if (isset($cached['certs']) && is_array($cached['certs'])) {
                return $cached['certs'];
            }
            throw new ApiException('Nao foi possivel obter as chaves de verificacao.', 500);
        }

        @file_put_contents($cacheFile, json_encode([
            'certs'   => $certs,
            'expires' => time() + max(300, $maxAge),
        ]));

        return $certs;
    }

    /** GET HTTP retornando [body, max-age]. Usa curl se disponivel, senao file_get_contents. */
    private static function httpGetWithMaxAge(string $url): array
    {
        $maxAge = 3600;

        if (function_exists('curl_init')) {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HEADER         => true,
                CURLOPT_TIMEOUT        => 10,
                CURLOPT_SSL_VERIFYPEER => true,
            ]);
            $raw = curl_exec($ch);
            if ($raw === false) {
                throw new ApiException('Falha ao contatar o servico de chaves.', 500);
            }
            $headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
            curl_close($ch);
            $headers = substr($raw, 0, $headerSize);
            $body = substr($raw, $headerSize);
            if (preg_match('/max-age=(\d+)/i', $headers, $m)) {
                $maxAge = (int) $m[1];
            }
            return [$body, $maxAge];
        }

        $ctx = stream_context_create(['http' => ['timeout' => 10]]);
        $body = @file_get_contents($url, false, $ctx);
        if ($body === false) {
            throw new ApiException('Falha ao contatar o servico de chaves.', 500);
        }
        foreach ($http_response_header ?? [] as $h) {
            if (preg_match('/max-age=(\d+)/i', $h, $m)) {
                $maxAge = (int) $m[1];
            }
        }
        return [$body, $maxAge];
    }

    private static function authorizationHeader(): ?string
    {
        if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            return $_SERVER['HTTP_AUTHORIZATION'];
        }
        if (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            return $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }
        if (function_exists('apache_request_headers')) {
            $headers = apache_request_headers();
            foreach ($headers as $k => $v) {
                if (strcasecmp($k, 'Authorization') === 0) {
                    return $v;
                }
            }
        }
        return null;
    }

    private static function b64urlDecode(string $data): string
    {
        $remainder = strlen($data) % 4;
        if ($remainder) {
            $data .= str_repeat('=', 4 - $remainder);
        }
        return (string) base64_decode(strtr($data, '-_', '+/'));
    }
}
