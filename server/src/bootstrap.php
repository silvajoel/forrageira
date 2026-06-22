<?php
declare(strict_types=1);

/**
 * Bootstrap: carrega config e todas as classes do backend.
 * (Sem Composer: requires explicitos.)
 */

error_reporting(E_ALL);
ini_set('display_errors', '0'); // nunca vazar stack trace ao cliente

$root = dirname(__DIR__);

$GLOBALS['app_config'] = require $root . '/config.php';

require $root . '/lib/Response.php';
require $root . '/lib/Db.php';
require $root . '/lib/Ids.php';
require $root . '/lib/FirebaseToken.php';
require $root . '/lib/Auth.php';
require $root . '/lib/Fcm.php';

require __DIR__ . '/Router.php';
require __DIR__ . '/Json.php';
require __DIR__ . '/Notifier.php';
require __DIR__ . '/controllers/UsersController.php';
require __DIR__ . '/controllers/AnalysisController.php';
require __DIR__ . '/controllers/SpeciesController.php';
require __DIR__ . '/controllers/NotificationsController.php';
require __DIR__ . '/controllers/AuditController.php';
require __DIR__ . '/controllers/UploadController.php';
