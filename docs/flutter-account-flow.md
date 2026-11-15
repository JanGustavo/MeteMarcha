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

Para ativar as chamadas de rede, compile com a origem HTTPS da API:

```sh
flutter run --dart-define=MM_API_URL=https://api.exemplo.com
```

O endereço não pode ser um domínio de exemplo no aplicativo distribuído. HTTP é
aceito apenas para `localhost` ou `127.0.0.1` em desenvolvimento. Sem
`MM_API_URL`, o cadastro e o login ficam indisponíveis e o app permite continuar
com os treinos locais. Antes de liberar a versão com conta obrigatória, configurar
o domínio real da VPS e testar o fluxo num aparelho.

## Verificação desta etapa

Os testes Flutter passaram, incluindo cadastro, login, expiração de sessão e
proteção do banco local contra outra conta. A análise não apontou erros nem
avisos; o SDK instalado em novembro de 2026 emitiu avisos informativos de API
`material.dart` depreciada em todo o projeto.

O APK não foi gerado: o Flutter instalado exige Gradle 9.3.1, mas o wrapper do
projeto está em 8.14. Dispensar a checagem de versão também falhou por
incompatibilidade da API do plugin Android. É preciso atualizar a configuração
Android e repetir o build antes de distribuir a tela de conta.
