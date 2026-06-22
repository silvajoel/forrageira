<?php
declare(strict_types=1);

/**
 * POST /upload  (multipart/form-data)
 * Campos: image (arquivo), analysis_id, title.
 * Adaptado do endpoint PHP original; agora exige autenticacao e salva no servidor da UFSJ.
 */
final class UploadController
{
    private const MAX_BYTES = 5 * 1024 * 1024;

    public static function store(): void
    {
        Auth::requireUser();
        $config = $GLOBALS['app_config'];

        if (!isset($_FILES['image'])) {
            Response::error('Nenhuma imagem enviada.', 422);
        }
        $file = $_FILES['image'];
        if ($file['error'] !== UPLOAD_ERR_OK) {
            Response::error('Erro no upload da imagem. Codigo: ' . $file['error'], 422);
        }
        if ($file['size'] > self::MAX_BYTES) {
            Response::error('Imagem muito grande. Maximo permitido: 5 MB.', 422);
        }

        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime = $finfo ? finfo_file($finfo, $file['tmp_name']) : null;
        if ($finfo) {
            finfo_close($finfo);
        }
        $allowed = ['image/jpeg' => 'jpg', 'image/png' => 'png'];
        if (!isset($allowed[$mime])) {
            Response::error('Arquivo invalido. Apenas imagens JPG e PNG sao permitidas.', 422);
        }

        $analysisId = self::sanitize($_POST['analysis_id'] ?? 'geral', 'geral');
        $titleSafe  = self::sanitize($_POST['title'] ?? 'foto', 'foto');

        $baseDir   = rtrim($config['uploads_dir'], '/');
        $uploadDir = $baseDir . '/' . $analysisId;
        if (!is_dir($uploadDir) && !mkdir($uploadDir, 0755, true) && !is_dir($uploadDir)) {
            Response::error('Nao foi possivel criar a pasta de uploads.', 500);
        }

        $fileName = sprintf('%s_%s_%s.%s', $titleSafe, gmdate('Ymd_His'), bin2hex(random_bytes(4)), $allowed[$mime]);
        $filePath = $uploadDir . '/' . $fileName;

        if (!move_uploaded_file($file['tmp_name'], $filePath)) {
            Response::error('Erro ao salvar a imagem no servidor.', 500);
        }

        $url = rtrim($config['uploads_base_url'], '/') . '/' . rawurlencode($analysisId) . '/' . rawurlencode($fileName);

        Response::success('Imagem salva com sucesso!', [
            'url'         => $url,
            'analysis_id' => $analysisId,
            'file_name'   => $fileName,
            'mime'        => $mime,
            'size'        => $file['size'],
        ]);
    }

    private static function sanitize(string $value, string $fallback): string
    {
        $clean = preg_replace('/[^A-Za-z0-9\-_]/', '_', $value);
        return ($clean === null || $clean === '') ? $fallback : $clean;
    }
}
