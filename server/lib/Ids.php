<?php
declare(strict_types=1);

/**
 * Geracao de IDs textuais (substitui o auto-ID do Firestore).
 * 20 caracteres alfanumericos, cabem em varchar(100).
 */
final class Ids
{
    public static function generate(int $length = 20): string
    {
        $alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        $max = strlen($alphabet) - 1;
        $out = '';
        for ($i = 0; $i < $length; $i++) {
            $out .= $alphabet[random_int(0, $max)];
        }
        return $out;
    }

    /** Data/hora atual em UTC no formato do MariaDB (datetime). */
    public static function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
