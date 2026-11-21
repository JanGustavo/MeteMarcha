# Cadastro e login no Flutter

O botão da abertura leva à entrada de conta. Quem ainda não tem conta vê o
cadastro; quem já tem conta pode alternar para login. Se o aparelho já contém
perfil ou divisão de treinos, a tela informa que esses dados permanecem locais e
preenche o nome existente no cadastro.

O app chama `POST /v1/auth/register` ou `POST /v1/auth/login`, guarda o token no
armazenamento seguro do sistema e valida a sessão com `GET /v1/me` ao abrir. Um
`401` limpa o token e pede login; uma falha de rede preserva o token para nova
tentativa. A opção de sair revoga a sessão em `POST /v1/auth/logout`.

O ID da primeira conta usada fica associado ao banco local. Uma conta diferente
não pode entrar nesse mesmo banco sem um fluxo futuro de troca ou importação de
dados. O cadastro **não envia** treinos, medidas ou fotos do aparelho ao servidor;
essa etapa depende da sincronização do histórico, ainda não implementada.

O app usa `https://api.metemarcha.jangustavo.me` por padrão. Para apontar uma
compilação de desenvolvimento para outra API, use:

```sh
flutter run --dart-define=MM_API_URL=https://api.exemplo.com
```

HTTP é aceito apenas para `localhost` ou `127.0.0.1` em desenvolvimento. Quem já
tem dados locais pode continuar usando os treinos sem conta. Antes de distribuir
o app, testar cadastro, login e preservação dos dados em um aparelho.

## Verificação desta etapa

Os 21 testes Flutter passaram, incluindo cadastro, login, expiração de sessão e
proteção do banco local contra outra conta. O APK debug e o APK release foram
gerados com Flutter 3.50, Gradle 9.3.1 e Android Gradle Plugin 9.1.1. O APK
release inclui a permissão `INTERNET`, e a API pública respondeu em `/healthz`.

O projeto mantém `android.builtInKotlin=false` e `android.newDsl=false` enquanto
os plugins Android dependem do plugin Kotlin antigo. O `file_picker` 11.x precisa
de um ajuste no Gradle raiz para compilar seu código Kotlin nessa configuração;
veja o [problema confirmado pelo mantenedor](https://github.com/vicajilau/flutter_file_picker/issues/2200).

Ainda falta instalar o APK em um aparelho e testar cadastro, login e preservação
dos dados locais contra a API real. Nenhum aparelho estava conectado ao ADB na
verificação. O build não criou uma conta de teste no servidor.
