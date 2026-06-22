<?php
declare(strict_types=1);

/**
 * Contexto do usuario autenticado para a requisicao atual.
 */
final class AuthContext
{
    public string $uid;
    public ?string $email;
    public ?string $name;
    /** Linha do usuario em `users` (pode ser null se ainda nao sincronizado). */
    public ?array $profile;

    public function __construct(string $uid, ?string $email, ?string $name, ?array $profile)
    {
        $this->uid     = $uid;
        $this->email   = $email;
        $this->name    = $name;
        $this->profile = $profile;
    }

    public function role(): string
    {
        return (string) ($this->profile['role'] ?? 'user');
    }

    public function isAdmin(): bool
    {
        return strtolower(trim($this->role())) === 'admin';
    }
}

final class Auth
{
    /** Verifica o token e carrega o perfil. Lanca ApiException(401) se invalido. */
    public static function requireUser(): AuthContext
    {
        $jwt    = FirebaseToken::fromAuthHeader();
        $claims = FirebaseToken::verify($jwt);

        $uid   = (string) $claims['sub'];
        $email = isset($claims['email']) ? (string) $claims['email'] : null;
        $name  = isset($claims['name']) ? (string) $claims['name'] : null;

        $profile = Db::first('SELECT * FROM users WHERE id = ?', [$uid]);

        return new AuthContext($uid, $email, $name, $profile);
    }

    /** Igual a requireUser, mas exige role admin e usuario ativo. */
    public static function requireAdmin(): AuthContext
    {
        $ctx = self::requireUser();
        if ($ctx->profile === null) {
            throw new ApiException('Usuario nao encontrado.', 403);
        }
        if ((int) ($ctx->profile['active'] ?? 1) === 0) {
            throw new ApiException('Usuario inativo.', 403);
        }
        if (!$ctx->isAdmin()) {
            throw new ApiException('Acesso restrito a administradores.', 403);
        }
        return $ctx;
    }
}
