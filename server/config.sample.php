<?php
declare(strict_types=1);

/**
 * Copie este arquivo para `config.local.php` no servidor e preencha os valores.
 * `config.local.php` NAO deve ir para o git (ver .gitignore).
 *
 * Alternativamente, defina as mesmas chaves como variaveis de ambiente
 * (ex.: no vhost do Apache com SetEnv) que terao prioridade.
 */
return [
    // Banco de dados (MariaDB local ao servidor)
    'db_host'     => '127.0.0.1',
    'db_port'     => 3306,
    'db_name'     => 'forrageira',
    'db_user'     => 'forrageira_user',
    'db_pass'     => 'TROQUE_AQUI',

    // Projeto Firebase (para validar o ID token e enviar push)
    'firebase_project_id' => 'forrageira-963b0',

    // Caminho ABSOLUTO do JSON da service account do Firebase (FORA do webroot).
    // Console Firebase -> Config. do projeto -> Contas de servico -> Gerar nova chave.
    'firebase_service_account' => '/etc/forrageira/service-account.json',

    // Diretorio onde as imagens enviadas sao salvas (precisa existir e ter escrita).
    'uploads_dir'  => __DIR__ . '/public/uploads',
    // URL publica base correspondente ao uploads_dir.
    'uploads_base_url' => 'https://capim.ufsj.edu.br/uploads',

    // Origens permitidas para CORS (app web). O app mobile nao precisa de CORS.
    'cors_allowed_origins' => [
        'https://forrageira-963b0.web.app',
        'https://forrageira.devjoelchagas.com.br',
        'https://capim.ufsj.edu.br',
    ],
];
