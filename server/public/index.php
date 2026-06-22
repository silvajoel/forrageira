<?php
declare(strict_types=1);

/**
 * Front controller da API Forrageira.
 * Todas as rotas /api/* sao roteadas para ca pelo .htaccess.
 */

require dirname(__DIR__) . '/src/bootstrap.php';

$config = $GLOBALS['app_config'];

// ----- CORS -----
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin !== '' && in_array($origin, $config['cors_allowed_origins'], true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
}
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Origin, Content-Type, Accept, Authorization');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ----- Caminho da rota (remove prefixo /api) -----
$uri  = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$path = preg_replace('#^.*?/api#', '', $uri); // tudo apos /api
$path = '/' . trim((string) $path, '/');

$router = new Router();

// Health check
$router->get('/health', function () {
    Response::success('API Forrageira ativa.', ['time' => Ids::now()]);
});

// Auth / usuarios
$router->get('/auth/admin-eligible', [UsersController::class, 'adminEligible']); // publico
$router->post('/auth/sync',          [UsersController::class, 'sync']);
$router->get('/users/me',            [UsersController::class, 'me']);
$router->put('/users/me/fcm-token',  [UsersController::class, 'saveFcmToken']);
$router->get('/users',               [UsersController::class, 'index']);
$router->post('/users',              [UsersController::class, 'create']);
$router->patch('/users/{id}',        [UsersController::class, 'update']);
$router->delete('/users/{id}',       [UsersController::class, 'delete']);

// Analises
$router->post('/analysis',                 [AnalysisController::class, 'create']);
$router->get('/analysis',                  [AnalysisController::class, 'index']);
$router->get('/analysis/{id}',             [AnalysisController::class, 'show']);
$router->post('/analysis/{id}/finalize',   [AnalysisController::class, 'finalize']);
$router->post('/analysis/{id}/reopen',     [AnalysisController::class, 'reopen']);

// Especies
$router->get('/species',        [SpeciesController::class, 'index']);
$router->post('/species',       [SpeciesController::class, 'create']);
$router->put('/species/{id}',   [SpeciesController::class, 'update']);
$router->delete('/species/{id}',[SpeciesController::class, 'delete']);

// Notificacoes
$router->get('/notifications',              [NotificationsController::class, 'index']);
$router->patch('/notifications/{id}/read',  [NotificationsController::class, 'markRead']);
$router->post('/notifications/read-all',    [NotificationsController::class, 'markAllRead']);

// Logs de auditoria
$router->get('/audit-logs',  [AuditController::class, 'index']);
$router->post('/audit-logs', [AuditController::class, 'create']);

// Upload de imagem
$router->post('/upload', [UploadController::class, 'store']);

try {
    $router->dispatch($_SERVER['REQUEST_METHOD'] ?? 'GET', $path);
} catch (ApiException $e) {
    Response::error($e->getMessage(), $e->httpCode());
} catch (Throwable $e) {
    error_log('[forrageira-api] ' . $e->getMessage());
    Response::error('Erro interno no servidor.', 500);
}
