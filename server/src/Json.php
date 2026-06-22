<?php
declare(strict_types=1);

/**
 * Utilitarios para ler o corpo JSON da requisicao.
 */
final class Json
{
    /** Decodifica o corpo JSON. Lanca ApiException(400) se invalido. */
    public static function body(): array
    {
        $raw = file_get_contents('php://input') ?: '';
        if (trim($raw) === '') {
            return [];
        }
        $data = json_decode($raw, true);
        if (!is_array($data)) {
            throw new ApiException('Corpo da requisicao deve ser JSON valido.', 400);
        }
        return $data;
    }

    /** Campo string obrigatorio. */
    public static function requireString(array $data, string $key): string
    {
        $v = $data[$key] ?? null;
        if (!is_string($v) || trim($v) === '') {
            throw new ApiException("Campo obrigatorio ausente: $key.", 422);
        }
        return $v;
    }

    public static function optString(array $data, string $key, ?string $default = null): ?string
    {
        $v = $data[$key] ?? null;
        return is_string($v) ? $v : $default;
    }

    public static function optBool(array $data, string $key, bool $default): bool
    {
        $v = $data[$key] ?? null;
        if (is_bool($v)) return $v;
        if (is_int($v)) return $v === 1;
        if (is_string($v)) return in_array(strtolower($v), ['1', 'true', 'yes'], true);
        return $default;
    }

    public static function optFloat(array $data, string $key, ?float $default = null): ?float
    {
        $v = $data[$key] ?? null;
        return is_numeric($v) ? (float) $v : $default;
    }
}
