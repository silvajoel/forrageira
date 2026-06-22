<?php
declare(strict_types=1);

/**
 * Carrega a configuracao com a seguinte prioridade:
 *   1. Variaveis de ambiente (FORRAGEIRA_DB_PASS, etc.) quando definidas.
 *   2. Arquivo config.local.php (gitignored) ao lado deste.
 *   3. config.sample.php (apenas defaults/placeholders).
 *
 * Nunca commitar segredos: use config.local.php ou variaveis de ambiente.
 */

$defaults = require __DIR__ . '/config.sample.php';

$local = [];
if (is_file(__DIR__ . '/config.local.php')) {
    $local = require __DIR__ . '/config.local.php';
}

$config = array_merge($defaults, $local);

// Sobrescreve por variaveis de ambiente (prefixo FORRAGEIRA_).
$envMap = [
    'db_host'                  => 'FORRAGEIRA_DB_HOST',
    'db_port'                  => 'FORRAGEIRA_DB_PORT',
    'db_name'                  => 'FORRAGEIRA_DB_NAME',
    'db_user'                  => 'FORRAGEIRA_DB_USER',
    'db_pass'                  => 'FORRAGEIRA_DB_PASS',
    'firebase_project_id'      => 'FORRAGEIRA_FIREBASE_PROJECT_ID',
    'firebase_service_account' => 'FORRAGEIRA_SERVICE_ACCOUNT',
    'uploads_dir'              => 'FORRAGEIRA_UPLOADS_DIR',
    'uploads_base_url'         => 'FORRAGEIRA_UPLOADS_BASE_URL',
];
foreach ($envMap as $key => $env) {
    $value = getenv($env);
    if ($value !== false && $value !== '') {
        $config[$key] = ($key === 'db_port') ? (int) $value : $value;
    }
}

return $config;
