# Guia de Verificação e Publicação FOSS - Mete Marcha 🚀

Este guia detalha os passos necessários para realizar a verificação de desenvolvedor exigida pelo Play Protect (prazo limite no Brasil: **Setembro de 2026**) e como distribuir o aplicativo em lojas e canais Open Source.

---

## 1. Verificação de Desenvolvedor (Play Protect) 🛡️

A partir de setembro de 2026, dispositivos Android certificados (com serviços Google e Play Protect) exigirão que aplicativos instalados por sideload (como as atualizações automáticas via GitHub) ou por lojas de terceiros sejam registrados por uma identidade de desenvolvedor verificada para evitar alertas persistentes de segurança.

### Passo a Passo para se Registrar:
1. **Console de Desenvolvedor Android:**
   * Crie ou acesse sua conta no [Android Developer Console / Google Play Console](https://developer.android.com/developer-verification).
   * Embora a publicação na Play Store exija uma taxa única de US$ 25, o registro de identidade (KYC) para legitimar assinaturas de APK para sideload é o foco principal da política de segurança de 2026.
2. **Processo de Identificação (KYC):**
   * Você precisará fornecer seus dados oficiais de desenvolvedor (nome legal, endereço residencial, e-mail e número de telefone verificado).
3. **Registro do App e Assinatura:**
   * Registre o **Package Name** do seu aplicativo (ex: `dev.jangustavo.metemarcha`).
   * Adicione o fingerprint SHA-256 da chave de assinatura do seu APK (a keystore que você configurou no `key.properties` para assinar a build no `release.sh`).
   * Isso associará seus APKs compilados à sua identidade oficial no Play Protect, liberando instalações via link do GitHub sem telas de bloqueio severas.

---

## 2. Alterando o Package Name (Recomendado) 📦

Atualmente o aplicativo utiliza o ID genérico `com.example.gym`. Antes de iniciar a verificação com o Google, é fundamental alterar o Package Name para um identificador definitivo e único, como `dev.jangustavo.metemarcha`.

### Como alterar de forma simples:
Você pode utilizar o pacote comunitário `change_app_package_name` para fazer isso automaticamente:

1. Adicione a dependência temporariamente em modo dev:
   ```bash
   flutter pub add dev:change_app_package_name
   ```
2. Execute o comando com o novo identificador:
   ```bash
   flutter pub run change_app_package_name:main dev.jangustavo.metemarcha
   ```
3. Remova a dependência:
   ```bash
   flutter pub remove change_app_package_name
   ```
4. Verifique as alterações nos arquivos nativos (ex: `AndroidManifest.xml`, `build.gradle.kts`, estruturas de pastas em `android/app/src/main/kotlin/`) e faça um commit.

---

## 3. Publicação em Lojas Open Source 🏪

### Canal 1: Obtainium (Menor Esforço) 🚀
O Obtainium é um agregador que busca lançamentos diretamente do repositório do GitHub e atualiza aplicativos sem intermediários.
* **Como funciona:** Como já temos o script `release.sh` gerando tags semver e publicando APKs nas Releases do GitHub, o Obtainium é suportado nativamente.
* **Instruções ao usuário:** Basta instruir seus usuários a instalar o Obtainium e adicionar o link do seu repositório:
  `https://github.com/JanGustavo/MeteMarcha`

### Canal 2: IzzyOnDroid (Intermediário) 📦
O IzzyOnDroid é um repositório extremamente popular compatível com clientes F-Droid que hospeda APKs compilados direto do GitHub Releases.
* **Ponto de Atenção:** O repositório proíbe ou sinaliza severamente aplicativos com permissões perigosas como `REQUEST_INSTALL_PACKAGES` e sistemas de auto-atualização interna (OTA).
* **Solução:** Compile uma versão dedicada (FOSS) sem essas características. 
  1. O código do atualizador em Dart agora suporta a flag `ENABLE_OTA`. Para compilar o APK sem a checagem interna de updates, use:
     ```bash
     flutter build apk --release --dart-define=ENABLE_OTA=false
     ```
  2. Remova a linha `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>` e a tag `<provider>` do OTA do `AndroidManifest.xml` antes de gerar a build para esta loja.
  3. Envie o link do repositório para submissão no site oficial do [IzzyOnDroid](https://apt.izzysoft.de/fdroid/).

### Canal 3: F-Droid Principal (Longo Prazo) 🕊️
O F-Droid oficial compila os aplicativos diretamente a partir do código fonte e exige builds 100% reprodutíveis e livres de dependências proprietárias.
* **Requisitos:**
  * O código fonte não deve conter blobs binários proprietários.
  * O atualizador interno (OTA) deve estar desativado (usando a flag `--dart-define=ENABLE_OTA=false` que implementamos).
* **Submissão:** O processo é realizado abrindo um Merge Request no repositório `fdroiddata` no GitLab do F-Droid, definindo a receita de build a partir da sua tag do GitHub.
