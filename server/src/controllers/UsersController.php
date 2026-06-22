<?php
declare(strict_types=1);

final class UsersController
{
    /**
     * POST /auth/sync
     * Garante a linha em `users` para o usuario autenticado (id = uid do token).
     * Cria na primeira vez; atualiza nome/email se vier no corpo. Retorna o perfil.
     */
    public static function sync(): void
    {
        $ctx  = Auth::requireUser();
        $body = Json::body();

        $name  = Json::optString($body, 'name', $ctx->name) ?? '';
        $email = Json::optString($body, 'email', $ctx->email) ?? '';

        if ($ctx->profile === null) {
            Db::run(
                'INSERT INTO users (id, name, email, role, active, created_at)
                 VALUES (?, ?, ?, ?, 1, ?)',
                [$ctx->uid, $name, $email, 'user', Ids::now()]
            );
        } else {
            // Atualiza apenas nome/email (nao mexe em role/active aqui).
            Db::run(
                'UPDATE users SET name = ?, email = ? WHERE id = ?',
                [
                    $name !== '' ? $name : $ctx->profile['name'],
                    $email !== '' ? $email : $ctx->profile['email'],
                    $ctx->uid,
                ]
            );
        }

        $profile = Db::first('SELECT * FROM users WHERE id = ?', [$ctx->uid]);
        Response::success('Usuario sincronizado.', self::serialize($profile));
    }

    /**
     * GET /auth/admin-eligible?email=...   (PUBLICO, sem token)
     * Usado no fluxo web de reset de senha admin (ocorre antes do login).
     * Retorna apenas um booleano para nao expor dados do usuario.
     */
    public static function adminEligible(): void
    {
        $email = isset($_GET['email']) ? strtolower(trim((string) $_GET['email'])) : '';
        $eligible = false;
        if ($email !== '') {
            $row = Db::first(
                "SELECT id FROM users WHERE LOWER(email) = ? AND role = 'admin' AND active = 1 LIMIT 1",
                [$email]
            );
            $eligible = $row !== null;
        }
        Response::success('ok', ['eligible' => $eligible]);
    }

    /** GET /users/me */
    public static function me(): void
    {
        $ctx = Auth::requireUser();
        if ($ctx->profile === null) {
            Response::error('Perfil ainda nao sincronizado.', 404);
        }
        Response::success('Perfil.', self::serialize($ctx->profile));
    }

    /** PUT /users/me/fcm-token  { "fcmToken": "..." } */
    public static function saveFcmToken(): void
    {
        $ctx = Auth::requireUser();
        $body = Json::body();
        $token = Json::requireString($body, 'fcmToken');

        // upsert defensivo: garante a linha mesmo se auth/sync nao tiver rodado.
        if ($ctx->profile === null) {
            Db::run(
                'INSERT INTO users (id, name, email, role, active, fcmToken, created_at)
                 VALUES (?, ?, ?, ?, 1, ?, ?)',
                [$ctx->uid, $ctx->name ?? '', $ctx->email ?? '', 'user', $token, Ids::now()]
            );
        } else {
            Db::run('UPDATE users SET fcmToken = ? WHERE id = ?', [$token, $ctx->uid]);
        }
        Response::success('Token salvo.');
    }

    /** GET /users  (admin) */
    public static function index(): void
    {
        Auth::requireAdmin();
        $rows = Db::all('SELECT * FROM users ORDER BY name ASC');
        Response::success('Usuarios.', array_map([self::class, 'serialize'], $rows));
    }

    /** POST /users  (admin)  cria cliente "manual" (sem conta Firebase ainda) */
    public static function create(): void
    {
        Auth::requireAdmin();
        $body = Json::body();
        $name  = Json::requireString($body, 'name');
        $email = Json::requireString($body, 'email');
        $role  = Json::optString($body, 'role', 'user') ?? 'user';
        $active = Json::optBool($body, 'active', true);

        $id = Ids::generate();
        Db::run(
            'INSERT INTO users (id, name, email, role, active, created_at) VALUES (?, ?, ?, ?, ?, ?)',
            [$id, $name, $email, $role, $active ? 1 : 0, Ids::now()]
        );
        $profile = Db::first('SELECT * FROM users WHERE id = ?', [$id]);
        Response::success('Usuario criado.', self::serialize($profile), 201);
    }

    /** PATCH /users/{id}  (admin)  atualiza name/email/active/role parcialmente */
    public static function update(array $params): void
    {
        Auth::requireAdmin();
        $id = $params['id'];
        $existing = Db::first('SELECT * FROM users WHERE id = ?', [$id]);
        if ($existing === null) {
            Response::error('Usuario nao encontrado.', 404);
        }
        $body = Json::body();

        $fields = [];
        $values = [];
        foreach (['name', 'email', 'role'] as $key) {
            if (array_key_exists($key, $body) && is_string($body[$key])) {
                $fields[] = "$key = ?";
                $values[] = $body[$key];
            }
        }
        if (array_key_exists('active', $body)) {
            $fields[] = 'active = ?';
            $values[] = Json::optBool($body, 'active', true) ? 1 : 0;
        }
        if ($fields === []) {
            Response::error('Nada para atualizar.', 422);
        }
        $values[] = $id;
        Db::run('UPDATE users SET ' . implode(', ', $fields) . ' WHERE id = ?', $values);

        $profile = Db::first('SELECT * FROM users WHERE id = ?', [$id]);
        Response::success('Usuario atualizado.', self::serialize($profile));
    }

    /** DELETE /users/{id}  (admin) */
    public static function delete(array $params): void
    {
        Auth::requireAdmin();
        Db::run('DELETE FROM users WHERE id = ?', [$params['id']]);
        Response::success('Usuario removido.');
    }

    /** Normaliza a linha do banco para o JSON consumido pelo app. */
    public static function serialize(?array $row): ?array
    {
        if ($row === null) {
            return null;
        }
        return [
            'id'         => $row['id'],
            'name'       => $row['name'],
            'email'      => $row['email'],
            'role'       => $row['role'],
            'active'     => (int) $row['active'] === 1,
            'fcmToken'   => $row['fcmToken'] ?? null,
            'created_at' => self::iso($row['created_at'] ?? null),
        ];
    }

    private static function iso(?string $dt): ?string
    {
        if ($dt === null || $dt === '') {
            return null;
        }
        return str_replace(' ', 'T', $dt) . 'Z';
    }
}
