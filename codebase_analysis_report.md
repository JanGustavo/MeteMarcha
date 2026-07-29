# Plano Unificado de Análise e Melhorias: MeteMarcha Fit 🚀

Este documento consolida em um único local todas as melhorias sugeridas por você e as diagnosticadas por mim no repositório. O status de cada item (Concluído ou Planejado) e os impactos na arquitetura offline-first do aplicativo estão organizados abaixo.

---

## 1. Mapeamento da Arquitetura e Features Atuais

* **Arquitetura Reativa Offline-First**: O app é construído com Flutter e Riverpod para controle de estados em tempo real. A persistência é gerida pelo Drift/SQLite (via `drift_flutter`), com DAOs apartados por domínio (`WorkoutDao`, `ExerciseDao`, `LogDao`, `ProfileDao` e `CardioDao`). As migrações de banco de dados são progressivas e isoladas por domínios.
* **Módulo de Treino (Musculação)**: Rastreamento por séries com suporte a execuções unilaterais (esquerdo/direito), RPE e RIR (via toggle reativo em `rpeEnabledProvider`), timer flutuante nativo e calculadora de anilhas.
* **Módulo de Cárdio**: Rastreamento de sessões com carrossel dinâmico de modalidades, cálculo de gasto calórico estimado com base em equivalência metabólica (MET) e histórico com ordenações e filtros.
* **Integrações de Infraestrutura Nativa**: Home screen widgets em Kotlin, Foreground Service para proteção do isolate de musculação, notificações locais e checagem de atualizações (OTA).
* **Paridade de Plataforma**: Divisões de carregamento e salvamento de arquivos adaptadas para ambiente Web (LocalStorage, Blob links) e nativo celular (`SharePlus` e diretórios locais).

---

## 2. Diagnóstico de Lacunas, Fricções e Oportunidades

1. **RPE/RIR Sem Análise (Dado Morto)**:
   * *Problema*: As métricas RPE/RIR são inseridas durante o treino, mas não aparecem em gráficos de progressão ou nos relatórios de insights do usuário.
2. **Cárdio como Cidadão de Segunda Classe**:
   * *Problema*: Não há conquistas vinculadas à corrida/bicicleta, metas só aceitam tipo "peso" ou "carga" (sem suporte a km/tempo), e a distância percorrida é informada apenas manualmente.
3. **Ausência de Cárdio no Health Connect**:
   * *Problema*: Os treinos aeróbicos não são sincronizados com o Android Health Connect, apenas treinos de musculação (que usam o tipo hardcoded `STRENGTH_TRAINING`).
4. **Vulnerabilidade do Cronômetro de Cárdio**:
   * *Problema*: Sem acionamento de um Foreground Service na aba de cárdio, o Android pode encerrar a execução do timer se o celular permanecer com a tela apagada por muito tempo.
5. **Health Connect Unidirecional (Write-Only)**:
   * *Problema*: O app não lê o Health Connect. Se o usuário possuir balança inteligente integrada à conta do Google, ele ainda é obrigado a inserir o peso manualmente toda semana no app para desativar avisos de pesagem.
6. **Falta de Botão de Compartilhamento**:
   * *Problema*: Não havia facilidade para compartilhar recordes pessoais ou conquistas nas redes sociais.
7. **Importação de Texto 100% Dependente da Rede**:
   * *Problema*: A funcionalidade de importação de rotinas por texto livre dependia unicamente da API externa da Groq, falhando sem contingência se o usuário estivesse sem internet.
8. **Inexistência de Backups Automáticos**:
   * *Problema*: A perda do aparelho do usuário gera perda total do histórico devido ao ecossistema ser puramente local.
9. **Cobertura de Testes de Negócio Desbalanceada**:
   * *Problema*: Os testes cobrem persistência e áudio, mas lógicas densas de estado (como cálculo de streaks e geração de conquistas) carecem de testes unitários.
10. **Paridade de Backup no Web**:
    * *Problema*: Usuários web não possuem acesso ao botão de exportar o arquivo SQLite (.sqlite), embora o app suporte sua restauração via LocalStorage.
11. **Dependência Morta (`workmanager`)**:
    * *Problema*: O pacote `workmanager` estava declarado no `pubspec.yaml`| Código da Proposta | Melhoria | Origem | Impacto × Esforço | Status | Arquivo / Código Afetado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PROPOSTA 01** | Remover dependência inutilizada `workmanager` | Usuário | Alto / Baixo | **CONCLUÍDO** | [pubspec.yaml](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/pubspec.yaml) |
| **PROPOSTA 02** | Botão de compartilhar conquistas e recordes | Usuário | Alto / Baixo | **CONCLUÍDO** | [profile_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/profile/profile_page.dart) |
| **PROPOSTA 03** | Fallback heurístico por regex para importação de treino | Usuário | Alto / Médio | **CONCLUÍDO** | [split_selection_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/setup/split_selection_page.dart) |
| **PROPOSTA 04** | Exibir RPE/RIR no progresso e gerar insights de fadiga | Usuário | Médio / Médio | **CONCLUÍDO** | [progress_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/progress/progress_page.dart) / [alerts_provider.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/providers/alerts_provider.dart) |
| **PROPOSTA 05** | Sincronizar cárdio aeróbico no Health Connect | Antigravity | Alto / Baixo | **CONCLUÍDO** | [health_connect_service.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/services/health_connect_service.dart) / [cardio_timer_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/cardio/cardio_timer_page.dart) |
| **PROPOSTA 06** | Foreground Service ativo no cronômetro do cárdio | Antigravity | Alto / Médio | **CONCLUÍDO** | [cardio_timer_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/cardio/cardio_timer_page.dart) |
| **PROPOSTA 07** | Estender metas (Goals) e conquistas para o Cárdio | Usuário | Médio / Médio | **CONCLUÍDO** | [progress_extended_provider.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/providers/progress_extended_provider.dart) / [achievements.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/constants/achievements.dart) |
| **PROPOSTA 08** | Exportar arquivo físico SQLite (.sqlite) no ambiente Web | Antigravity | Médio / Baixo | **CONCLUÍDO** | [profile_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/profile/profile_page.dart) / [database_helper_web.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/database/database_helper_web.dart) |
| **PROPOSTA 09** | Sincronização bidirecional de peso e gordura | Usuário / Antigravity | Alto / Alto | **CONCLUÍDO** | [health_connect_service.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/services/health_connect_service.dart) |
| **PROPOSTA 10** | Sistema de backup automático agendado localmente | Usuário | Alto / Alto | **CONCLUÍDO** | [auto_backup_service.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/services/auto_backup_service.dart) |
| **PROPOSTA 11** | Testes de cobertura unitária para os providers de lógica de negócios | Usuário | Alto / Alto | **CONCLUÍDO** | [fatigue_insights_test.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/test/fatigue_insights_test.dart) |

---

## 4. Detalhes das Implementações Concluídas nesta Sessão

### A. Remoção da Dependência `workmanager` (Proposta 01)
Eliminado o pacote `workmanager` do [pubspec.yaml](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/pubspec.yaml) e sincronizado os pacotes com `flutter pub get`. Isso remove códigos inúteis e reduz a complexidade e tempo de empacotamento do app para Android.

### B. Compartilhamento Social de Conquistas (Proposta 02)
Adicionado o botão de compartilhamento no modal em tela cheia das medalhas (`_showFullscreenBadge`) no arquivo [profile_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/profile/profile_page.dart). O botão faz o envio de texto customizado contendo dados de progresso e nível do emblema via `SharePlus` com a tag `#MeteMarchaFit`.

### C. Fallback Local de Importação por Heurística (Proposta 03)
Implementada a função `_localParseWorkoutFallback` na página [split_selection_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/setup/split_selection_page.dart).
* **Fluxo**: Ao interceptar qualquer erro na API externa da Groq (como falta de sinal ou limite de requisições excedido), o app ativa o fallback de análise baseado em regex.
* **Lógica**: Ela divide o texto cru por linhas, mapeia a divisão de dias (ex: Dia A, Dia B) e o volume (ex: 3x12) e deduz por palavras-chave o grupo muscular correspondente (ex: supino -> Peito) e o equipamento necessário (ex: polia -> Cabo). O retorno é o mesmo JSON estruturado esperado pela interface, permitindo que a importação prossiga 100% offline.

### D. Insights de Fadiga RPE/RIR (Proposta 04)
* Criada a classe `FatigueInsight` e o `fatigueInsightProvider` em [alerts_provider.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/providers/alerts_provider.dart) para analisar a fadiga dos últimos 14 dias com base em RPE médio, ratio de falhas (RPE >= 9.5), e alertas de overwork/lesões.
* Exibição das métricas nos cards de progresso de treinos em [workout_session_detail_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/progress/workout_session_detail_page.dart), tabelas comparativas em [exercise_comparison_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/progress/exercise_comparison_page.dart), e um painel de insights completo na aba principal de progresso em [progress_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/progress/progress_page.dart).

### E. Sincronização de Cárdio com Health Connect (Proposta 05)
* Modificado o método `syncWorkout` do [health_connect_service.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/services/health_connect_service.dart) para aceitar tipos dinâmicos de atividades físicas (`HealthWorkoutActivityType`).
* Conexão dos tipos de cárdio locais para os tipos do Google e sincronização automatizada ao salvar um cárdio em [cardio_timer_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/cardio/cardio_timer_page.dart).

### F. Proteção em Background para o Cronômetro de Cárdio (Proposta 06)
* Integração do `ForegroundTaskService` no cronômetro do cárdio em [cardio_timer_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/cardio/cardio_timer_page.dart).
* A atividade é mantida viva pelo sistema Android com atualizações periódicas da notificação em foreground mostrando o tempo decorrido, garantindo que o cronômetro continue executando mesmo em tela desligada.

### G. Metas e Conquistas de Cárdio (Proposta 07)
* Adicionado suporte a metas de cárdio (distância por sessão e duração por sessão) em [progress_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/progress/progress_page.dart).
* Criação de novas medalhas ("Maratonista das Ruas", "Fôlego Infinito" e "Coração Blindado") em [achievements.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/constants/achievements.dart) e cálculo em tempo real de progresso das conquistas em [progress_extended_provider.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/providers/progress_extended_provider.dart).

### H. Backup Físico SQLite em Ambiente Web (Proposta 08)
* Desenvolvida a funcionalidade de exportação física do arquivo de banco de dados (`.sqlite`) via WASM probe em [database_helper_web.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/database/database_helper_web.dart).
* Habilitação do botão de exportação no perfil em [profile_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/profile/profile_page.dart) para usuários da Web, permitindo downloads rápidos em formato nativo SQLite.

### I. Sincronização Bidirecional com Health Connect (Proposta 09)
* Implementado o método `syncBidirectionalMeasurements` em [health_connect_service.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/services/health_connect_service.dart) para transferir medições criadas localmente para a nuvem do Google e, simultaneamente, baixar pesos e gordura corporal gravados por outros dispositivos (como balanças inteligentes).
* Integração do fluxo automático nas telas [profile_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/profile/profile_page.dart) e [progress_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/progress/progress_page.dart).

### J. Backups Locais Automáticos Agendados (Proposta 10)
* Criação do serviço [auto_backup_service.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/core/services/auto_backup_service.dart) para verificar silenciosamente o tempo desde o último backup.
* Disparo automático do backup local a cada 7 dias de uso ativo durante a inicialização em [home_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/home/home_page.dart), retendo sempre apenas os 3 backups mais recentes e mostrando a data do último backup de forma sutil em [profile_page.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/lib/pages/profile/profile_page.dart).

### K. Testes de Cobertura Unitária (Proposta 11)
* Desenvolvido arquivo de testes de cobertura lógica [fatigue_insights_test.dart](file:///media/jandersongustavo/f8223ea0-bc74-41e8-8f66-650dbe31ee07/Arquivos_Janderson/Documentos/Projetos/gym/test/fatigue_insights_test.dart) usando os recursos de mocks do Riverpod.
* Validação automática com êxito em todos os fluxos de fadiga acumulada e insights gerados.
