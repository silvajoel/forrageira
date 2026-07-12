# Preparo de assinatura iOS para build na MacinCloud

Gerado para deixar o build pronto sem precisar de admin/root na máquina remota.
Todos os passos abaixo até o item 6 são feitos aqui no Windows.

## 0. Pré-requisito
Conta paga no Apple Developer Program ativa (necessária para gerar certificado
de Distribution e enviar para a App Store — a conta gratuita não permite isso).

## 1. Corrigir o Bundle ID no Firebase Console
Firebase Console > Configurações do projeto > Seus apps > app iOS "forrageira".
Editar o campo "ID do pacote" de `com.example.forrageira` para `br.edu.ufsj.forrageira`.
Se o console não permitir editar, adicionar um novo app iOS com esse bundle ID
no mesmo projeto (`forrageira-963b0`) e depois remover o antigo.
Baixar o `GoogleService-Info.plist` atualizado e enviar o conteúdo (não é segredo,
só chaves públicas do Firebase) para eu colocar em `ios/Runner/`.

## 2. Registrar o App ID na Apple
developer.apple.com > Certificates, Identifiers & Profiles > Identifiers > "+"
- Bundle ID: `br.edu.ufsj.forrageira` (explicit, não wildcard)
- Capabilities: habilitar "Sign In with Google" não existe nativamente; habilitar
  "Push Notifications" se o app usa firebase_messaging, e "Associated Domains" se
  usar deep links.

## 3. Gerar o CSR (Certificate Signing Request) via OpenSSL — sem Mac
No Windows (Git Bash, que já vem com OpenSSL):

```bash
openssl genrsa -out ios_distribution.key 2048
openssl req -new -key ios_distribution.key -out ios_distribution.csr \
  -subj "/emailAddress=silvajoel06@aluno.ufsj.edu.br, CN=Forrageira Distribution, C=BR"
```

Guarde `ios_distribution.key` em local seguro — é a chave privada do certificado,
NUNCA vai para o git (já está no `.gitignore`).

## 4. Criar o certificado de Distribution na Apple
developer.apple.com > Certificates > "+" > Apple Distribution
- Upload do `ios_distribution.csr`
- Baixar o `.cer` gerado (ex: `distribution.cer`)

## 5. Combinar certificado + chave privada em .p12 — sem Mac
```bash
openssl x509 -in distribution.cer -inform DER -out distribution.pem -outform PEM
openssl pkcs12 -export -inkey ios_distribution.key -in distribution.pem \
  -out distribution.p12 -name "Forrageira Distribution"
```
Você vai definir uma senha para o `.p12` nesse comando — anote, vai usar para
importar no Keychain da MacinCloud.

## 6. Criar o Provisioning Profile
developer.apple.com > Profiles > "+" > App Store
- App ID: `br.edu.ufsj.forrageira`
- Certificate: o "Forrageira Distribution" criado no passo 4
- Nome do profile: anotar exatamente (vai substituir os placeholders abaixo)
- Baixar o `.mobileprovision`

## 7. Preencher os placeholders no repo
Depois de ter Team ID (Apple Developer > Membership) e o nome do profile, substituir:
- `ios/Runner.xcodeproj/project.pbxproj`: `TEAM_ID_PLACEHOLDER` e
  `NOME_DO_PROVISIONING_PROFILE_PLACEHOLDER` (2 ocorrências, config Release)
- `ios/ExportOptions.plist`: `TEAM_ID` e `NOME_DO_PROVISIONING_PROFILE`

## 8. Levar para a MacinCloud
Transferir (fora do git, ex: upload direto na sessão remota ou serviço de
transferência temporário): `distribution.p12` + senha, `*.mobileprovision`,
`GoogleService-Info.plist`.

Na MacinCloud (nenhum passo abaixo precisa de sudo/admin):
1. Duplo-clique no `.p12` → abre o Keychain Access → pede a senha → importa.
2. Copiar o `.mobileprovision` para `~/Library/MobileDevice/Provisioning Profiles/`.
3. Arrastar o `GoogleService-Info.plist` para o target Runner no Xcode (única
   etapa que precisa da UI do Xcode).
4. `git clone`, `flutter pub get`, `cd ios && pod install`.
5. `flutter build ipa --export-options-plist=ios/ExportOptions.plist`
6. `xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u SEU_APPLE_ID -p SENHA_DE_APP` — gera a senha de app em appleid.apple.com > Segurança > Senhas de app.
