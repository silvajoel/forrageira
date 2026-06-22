<?php
declare(strict_types=1);

/**
 * Helpers de resposta JSON, no mesmo formato do endpoint PHP atual:
 *   { "status": "...", "message": "...", "data": {...} }
 */
final class Response
{
    public static function json(string $status, string $message, $data = [], int $httpCode = 200): void
    {
        http_response_code($httpCode);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode(
            ['status' => $status, 'message' => $message, 'data' => $data],
            JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
        );
        exit;
    }

    public static function success(string $message, $data = [], int $httpCode = 200): void
    {
        self::json('success', $message, $data, $httpCode);
    }

    public static function error(string $message, int $httpCode = 400, $data = []): void
    {
        self::json('error', $message, $data, $httpCode);
    }
}

/**
 * Excecao com codigo HTTP associado, capturada pelo router.
 */
final class ApiException extends Exception
{
    private int $httpCode;

    public function __construct(string $message, int $httpCode = 400)
    {
        parent::__construct($message);
        $this->httpCode = $httpCode;
    }

    public function httpCode(): int
    {
        return $this->httpCode;
    }
}
