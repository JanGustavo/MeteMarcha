# Implantação na VPS compartilhada

`newDeploy.sh` adapta o fluxo de implantação do CronFlow ao MeteMarcha. Há um
único binário Go e um serviço systemd; o aplicativo Flutter não é hospedado
nesta VPS. O script compila localmente em Linux x86_64 com CGO, testa o backend,
envia o binário, preserva banco/mídia em backup antes de atualizações, instala o
serviço e cria um site Nginx exclusivo. Após o health check local, o Certbot
emite o certificado e o script ativa o proxy HTTPS. Antes disso, o site HTTP
responde apenas ao desafio do certificado; a API não fica exposta sem TLS.
Sites e serviços existentes não são substituídos.

## Porta e pré-requisitos

A porta TCP **8084** estava livre na inspeção de 15/11/2026 e foi escolhida
para `127.0.0.1:8084`. O script verifica novamente antes de implantar. A VPS
compartilha Nginx com outros aplicativos e não tem Go/GCC instalados; por isso
o build ocorre na máquina local. O script não abre portas no firewall e mantém
a API inacessível diretamente pela rede.
O binário de teste exigiu GLIBC 2.34; a VPS tem GLIBC 2.39. O script também
confere as bibliotecas do binário enviado antes de parar um serviço existente.

## Uso

```sh
./backend/deploy/newDeploy.sh inspect HOST CAMINHO_DA_CHAVE USUARIO
./backend/deploy/newDeploy.sh deploy HOST CAMINHO_DA_CHAVE USUARIO DOMINIO_API EMAIL_CERTIFICADO
```

`inspect` é somente leitura. `deploy` exige que `DOMINIO_API` já resolva para a
VPS. A chave SSH precisa ser conhecida em `known_hosts`; o script não desliga a
verificação da identidade do servidor. Para mudar a porta local:

```sh
MM_DEPLOY_PORT=18081 ./backend/deploy/newDeploy.sh inspect HOST CHAVE USUARIO
```

Antes de `deploy`, escolher um domínio exclusivo da API e colocar o registro
DNS. Depois do deploy, configurar o Flutter com
`--dart-define=MM_API_URL=https://DOMINIO_API`. As músicas do catálogo devem ser
arquivos autorizados em `/var/lib/metemarcha/music`, com `catalog.json`; o
servidor também funciona sem catálogo. Os backups ficam em
`/opt/metemarcha/backups` e precisam de política de retenção fora deste script.

Se o health check local falhar, o script para antes de alterar o Nginx e deixa
o backup disponível. Uma atualização que aplique migrações ao banco exige
restauração conjunta do backup de dados se for necessário voltar à versão
anterior do binário.
