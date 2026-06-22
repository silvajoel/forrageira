<?php
declare(strict_types=1);

final class SpeciesController
{
    /** GET /species?active=1  (qualquer usuario autenticado) */
    public static function index(): void
    {
        Auth::requireUser();
        if (isset($_GET['active'])) {
            $active = in_array(strtolower((string) $_GET['active']), ['1', 'true', 'yes'], true) ? 1 : 0;
            $rows = Db::all('SELECT * FROM species WHERE active = ? ORDER BY name ASC', [$active]);
        } else {
            $rows = Db::all('SELECT * FROM species ORDER BY name ASC');
        }
        Response::success('Especies.', array_map([self::class, 'serialize'], $rows));
    }

    /** POST /species  (admin) { name, description } */
    public static function create(): void
    {
        $ctx = Auth::requireAdmin();
        $body = Json::body();
        $name = Json::requireString($body, 'name');
        $desc = Json::requireString($body, 'description');

        $id = Ids::generate();
        $now = Ids::now();
        Db::run(
            'INSERT INTO species (id, name, description, active, created_by, updated_by, created_at, updated_at)
             VALUES (?, ?, ?, 1, ?, ?, ?, ?)',
            [$id, $name, $desc, $ctx->uid, $ctx->uid, $now, $now]
        );
        self::writeLog($ctx, 'Especie criada', 'create', $id, "Especie \"$name\" cadastrada.");

        Response::success('Especie criada.', self::serialize(Db::first('SELECT * FROM species WHERE id = ?', [$id])), 201);
    }

    /** PUT /species/{id}  (admin) { name?, description?, active? } */
    public static function update(array $params): void
    {
        $ctx = Auth::requireAdmin();
        $id = $params['id'];
        $existing = Db::first('SELECT * FROM species WHERE id = ?', [$id]);
        if ($existing === null) {
            Response::error('Especie nao encontrada.', 404);
        }
        $body = Json::body();

        $fields = ['updated_by = ?', 'updated_at = ?'];
        $values = [$ctx->uid, Ids::now()];
        foreach (['name', 'description'] as $key) {
            if (array_key_exists($key, $body) && is_string($body[$key])) {
                $fields[] = "$key = ?";
                $values[] = $body[$key];
            }
        }
        if (array_key_exists('active', $body)) {
            $fields[] = 'active = ?';
            $values[] = Json::optBool($body, 'active', true) ? 1 : 0;
        }
        $values[] = $id;
        Db::run('UPDATE species SET ' . implode(', ', $fields) . ' WHERE id = ?', $values);

        $name = $body['name'] ?? $existing['name'];
        self::writeLog($ctx, 'Especie atualizada', 'update', $id, "Especie \"$name\" atualizada.");

        Response::success('Especie atualizada.', self::serialize(Db::first('SELECT * FROM species WHERE id = ?', [$id])));
    }

    /** DELETE /species/{id}  (admin) -> inativa (soft delete) */
    public static function delete(array $params): void
    {
        $ctx = Auth::requireAdmin();
        $id = $params['id'];
        $existing = Db::first('SELECT * FROM species WHERE id = ?', [$id]);
        if ($existing === null) {
            Response::error('Especie nao encontrada.', 404);
        }
        Db::run('UPDATE species SET active = 0, updated_by = ?, updated_at = ? WHERE id = ?',
            [$ctx->uid, Ids::now(), $id]);
        self::writeLog($ctx, 'Especie inativada', 'delete', $id, "Especie \"{$existing['name']}\" inativada.");
        Response::success('Especie inativada.');
    }

    private static function writeLog(AuthContext $ctx, string $action, string $type, string $typeId, string $details): void
    {
        $adminName = (string) ($ctx->profile['name'] ?? 'Admin');
        Db::run(
            'INSERT INTO logs (id, action, details, table_name, type, type_id, admin_id, admin_name, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [Ids::generate(), $action, $details, 'species', $type, $typeId, $ctx->uid, $adminName, Ids::now()]
        );
    }

    public static function serialize(array $row): array
    {
        return [
            'id'          => $row['id'],
            'name'        => $row['name'],
            'description' => $row['description'] ?? '',
            'active'      => (int) $row['active'] === 1,
            'created_at'  => self::iso($row['created_at'] ?? null),
            'updated_at'  => self::iso($row['updated_at'] ?? null),
        ];
    }

    private static function iso(?string $dt): ?string
    {
        return ($dt === null || $dt === '') ? null : str_replace(' ', 'T', $dt) . 'Z';
    }
}
