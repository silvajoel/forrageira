# Deploy da API Forrageira (servidor UFSJ — nginx + PHP-FPM + MariaDB)

O servidor `capim.ufsj.edu.br` roda **nginx/1.24 (Ubuntu)** e hoje mostra a pagina
padrao "Welcome to nginx". Os passos abaixo publicam a API e habilitam HTTPS
(obrigatorio: o app Android nao aceita HTTP em texto puro).

> Rode tudo no servidor (`acir@172.18.4.32`). Onde houver `sudo`, use a conta com permissao.

## 1. Copiar o backend para o servidor

Coloque a pasta `server/` (deste repo) em, por exemplo, `/var/www/forrageira/server`.
A raiz publica (document root) e `server/public`.

```bash
sudo mkdir -p /var/www/forrageira
# (envie os arquivos via git/scp/rsync) -> /var/www/forrageira/server
sudo chown -R www-data:www-data /var/www/forrageira
```

## 2. Conferir extensoes do PHP

```bash
php -v
php -m | grep -iE 'pdo_mysql|openssl|curl|fileinfo'   # devem aparecer os 4
ls /run/php/                                           # anote a versao do socket (ex.: php8.3-fpm.sock)
```

Confirme upload >= 5MB em `php.ini` (do FPM):

```bash
php -i | grep -iE 'upload_max_filesize|post_max_size'  # ambos >= 6M
```

## 3. Config do app (segredos fora do git)

```bash
cd /var/www/forrageira/server
cp config.sample.php config.local.php
# edite config.local.php: db_pass, firebase_service_account (caminho do JSON), uploads_*
```

Crie a pasta de uploads com escrita para o php-fpm:

```bash
sudo mkdir -p /var/www/forrageira/server/public/uploads
sudo chown -R www-data:www-data /var/www/forrageira/server/public/uploads
```

## 4. Rodar o ALTER TABLE no banco

```bash
mariadb -u forrageira_user -p forrageira < /var/www/forrageira/server/schema/alter.sql
```

## 5. Service account do Firebase (para o push)

No Firebase Console -> Configuracoes do projeto -> Contas de servico -> "Gerar nova
chave privada". Envie o JSON para o servidor FORA do webroot, ex.:

```bash
sudo mkdir -p /etc/forrageira
sudo mv service-account.json /etc/forrageira/service-account.json
sudo chown www-data:www-data /etc/forrageira/service-account.json
sudo chmod 600 /etc/forrageira/service-account.json
# aponte 'firebase_service_account' no config.local.php para esse caminho
```

## 6. Habilitar o site no nginx

```bash
sudo cp deploy/nginx-forrageira.conf /etc/nginx/sites-available/forrageira
# AJUSTE root e a versao do php-fpm dentro do arquivo
sudo ln -s /etc/nginx/sites-available/forrageira /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default       # remove a pagina padrao
sudo nginx -t && sudo systemctl reload nginx
```

Teste local (HTTP) no proprio servidor:

```bash
curl -s http://localhost/api/health
# esperado: {"status":"success","message":"API Forrageira ativa.","data":{...}}
```

## 7. HTTPS (obrigatorio para o app)

A porta 80 ja e acessivel externamente, entao o Let's Encrypt funciona:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d capim.ufsj.edu.br --redirect
sudo nginx -t && sudo systemctl reload nginx
```

O certbot cria o bloco `listen 443 ssl` e o redirect 80->443 automaticamente.
(Se a UFSJ fornecer um certificado proprio, instale-o no lugar do certbot.)

## 8. Testes finais

```bash
curl -s https://capim.ufsj.edu.br/api/health            # 200 + JSON
curl -s -o /dev/null -w "%{http_code}\n" https://capim.ufsj.edu.br/api/users/me   # 401 sem token (correto)
```

Com um ID token real do app (logue no app, copie o token):

```bash
curl -s -H "Authorization: Bearer <ID_TOKEN>" https://capim.ufsj.edu.br/api/users/me
```

Depois disso o app (build 1.0.10+14) ja funciona apontando para a UFSJ.
