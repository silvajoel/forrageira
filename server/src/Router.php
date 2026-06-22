<?php
declare(strict_types=1);

/**
 * Router minimalista: casa metodo + caminho (com {param}) e chama o handler.
 */
final class Router
{
    /** @var array<int,array{method:string,regex:string,vars:string[],handler:callable}> */
    private array $routes = [];

    public function add(string $method, string $path, callable $handler): void
    {
        $vars = [];
        $regex = preg_replace_callback('/\{(\w+)\}/', function ($m) use (&$vars) {
            $vars[] = $m[1];
            return '([^/]+)';
        }, $path);
        $this->routes[] = [
            'method'  => strtoupper($method),
            'regex'   => '#^' . $regex . '$#',
            'vars'    => $vars,
            'handler' => $handler,
        ];
    }

    public function get(string $p, callable $h): void    { $this->add('GET', $p, $h); }
    public function post(string $p, callable $h): void   { $this->add('POST', $p, $h); }
    public function put(string $p, callable $h): void    { $this->add('PUT', $p, $h); }
    public function patch(string $p, callable $h): void  { $this->add('PATCH', $p, $h); }
    public function delete(string $p, callable $h): void { $this->add('DELETE', $p, $h); }

    public function dispatch(string $method, string $path): void
    {
        $method = strtoupper($method);
        $pathMatchedButMethod = false;

        foreach ($this->routes as $route) {
            if (!preg_match($route['regex'], $path, $matches)) {
                continue;
            }
            if ($route['method'] !== $method) {
                $pathMatchedButMethod = true;
                continue;
            }
            $params = [];
            foreach ($route['vars'] as $i => $name) {
                $params[$name] = urldecode($matches[$i + 1]);
            }
            $route['handler']($params);
            return;
        }

        if ($pathMatchedButMethod) {
            Response::error('Metodo nao permitido.', 405);
        }
        Response::error('Recurso nao encontrado.', 404);
    }
}
