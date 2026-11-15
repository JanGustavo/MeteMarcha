# Plano de refatoração do frontend — MeteMarcha

## Objetivo

Preparar o Flutter existente para evoluir sem reescrever o aplicativo. A primeira
entrega separa componentes por responsabilidade, preservando layout, textos,
fluxos, cálculos e persistência. Modularizar não significa minificar o código ou
reduzir automaticamente o APK.

Backend em Go, endpoints, autenticação, banco remoto e implantação serão tratados
em outro trabalho. Não adicionar dependências de rede nesta refatoração.

## Como o Codex deve trabalhar

1. Ler esta página e os componentes envolvidos antes de editar.
2. Trabalhar em branch própria; apresentar mudanças para revisão sem fazer merge.
3. Escolher uma responsabilidade por etapa, com mudanças pequenas e verificáveis.
4. Manter os pontos de entrada públicos `ProgressPage`, `ProfilePage` e
   `WorkoutPage`, incluindo seus parâmetros.
5. Extrair widgets para bibliotecas Dart normais, com imports explícitos. Evitar
   `part` para compartilhar o estado privado de uma página gigante.
6. Passar dados e callbacks aos componentes. Manter Riverpod quando o componente
   já consome providers; não introduzir outro gerenciador de estado.
7. Não alterar regras de treino, cálculos, schema, dados ou integrações para
   aproveitar a refatoração. Registrar correções de comportamento separadamente.
8. Usar nomes ligados à função (`WorkoutSetInput`, `MeasurementCard`), sem arquivos
   genéricos como `utils2.dart` ou classes `Manager` sem responsabilidade clara.
9. Preferir componentes de algumas centenas de linhas. Arquivos acima de 600–800
   linhas devem motivar revisão, não divisões artificiais para cumprir um número.
10. Executar formatação, análise e testes apropriados. Registrar limitações e
    falhas já presentes na base, sem ocultá-las com ignores globais.

## Etapa 1 — extração inicial

### Progresso

- Separar gráficos, frequência, metas, recordes, força relativa e insights.
- Separar a aba de medidas de seus cards, gráfico, formulário e visualizador.
- Separar a aba de cárdio e seu gráfico.
- Mover a detecção de platôs para `progress/logic/plateau_detection.dart`, mantendo
  o algoritmo original.
- Deixar `progress_page.dart` responsável pela composição e navegação das abas.

### Perfil

- Extrair conquista e seus elementos visuais, banner de IMC, linha de peso e
  preferências de áudio.
- Manter nesta entrega os formulários, configurações e ações existentes na página.

### Treino

- Extrair descanso, desempenho anterior, lista de séries, campos numéricos,
  ações, etiquetas e painel de referências.
- Separar a representação local `WorkoutSetEntry` e os controladores de edição.
- Manter a orquestração da sessão e das integrações na página nesta entrega.

### Critérios de aceitação

- [x] Sintaxe válida e imports locais apontando para arquivos existentes.
- [x] Formatação dos arquivos alterados conferida.
- [ ] Análise sem novos erros ou avisos atribuíveis à mudança.
- [ ] Testes existentes relevantes executados e resultados documentados.
- [x] Corpos extraídos preservados, exceto renomes necessários entre bibliotecas
  e suporte opcional a `key` nos widgets públicos.
- [x] Nenhuma alteração em banco, providers, backend ou dependências.

### Resultado desta primeira entrega

| Página | Linhas antes | Linhas depois |
| --- | ---: | ---: |
| Progresso | 5.773 | 321 |
| Perfil | 3.137 | 2.669 |
| Treino | 4.115 | 3.173 |

Foram extraídas 36 bibliotecas Dart novas, agrupadas por responsabilidade. Código
de gráficos já inteiramente comentado foi removido; seu histórico permanece no
Git. Uma checagem offline com o parser do Dart analisou os três arquivos originais
e as 39 bibliotecas resultantes: 63 declarações preservadas, normalizando apenas
renomes, vírgulas opcionais de formatação e parâmetros opcionais `super.key`.
Também foram conferidos os caminhos dos imports locais e `git diff --check`.

`flutter analyze`, `flutter test` e build não foram executados: a preparação do
Flutter foi bloqueada pela revisão automática do ambiente ao tentar acessar o
endpoint de metadados da infraestrutura. A verificação offline de sintaxe e
preservação de declarações não substitui resolução de tipos, execução dos testes
ou validação em Android. Manter a entrega como rascunho até essas verificações.

## Etapa 2 — composição das telas restantes

Perfil e Treino ainda terão orquestradores grandes após a primeira extração.
Continuar em entregas independentes:

### Entrega em andamento — identificação do Perfil

- Formulário de avatar, nome, altura, peso e IMC extraído para
  `ProfileIdentificationCard`.
- `ProfilePage` mantém os controladores, a gravação e as ações de foto; o card
  recebe os dados e callbacks necessários.
- Verificações locais: `git diff --check` e conferência de imports concluídas.
  `flutter analyze`, `flutter test` e `dart format` dependem de instalar o SDK,
  ausente neste ambiente.

1. **Perfil:** extrair seções de identificação, permissões, lembretes,
   configurações e transferência de dados. Ações dependentes de estado devem ter
   callbacks explícitos; não mover todo o `State` para um mixin gigante.
2. **Treino:** separar resumo de conclusão/compartilhamento, edição de séries,
   seleção de exercício e detalhes de recordes.
3. **Progresso:** avaliar divisão adicional do card de força e da apresentação de
   conquistas se suas responsabilidades continuarem difíceis de acompanhar.
4. **Outras telas:** revisar Home, Setup e seleção de divisão depois desses fluxos,
   com a mesma estratégia.

## Etapa 3 — serviços locais e lógica testável

- Isolar captura, cópia e exclusão de fotos em serviço local.
- Isolar exportação/importação e geração de arquivos sem alterar seu formato.
- Separar cálculos de progresso de widgets, um algoritmo por mudança.
- Verificar atualização dos providers após gravações em tarefa própria.
- Tratar consistência do backup de fotos em tarefa própria; o backup atual do
  SQLite não implica backup dos arquivos de imagem.

Não executar essas correções junto de uma movimentação mecânica de widgets.

## Etapa 4 — frontend social, após contrato com o backend

Somente iniciar depois de definir com o responsável pelo Go os formatos e erros
da API, autenticação e regras de visibilidade.

Escopo previsto:

- Uma roda privada por participante no piloto, com convites.
- Feed vertical de stories com uma foto, faixa do catálogo e reações.
- Visibilidade no grupo por 24 horas; recuperação pelo autor até 72 horas desde
  a publicação; após isso a mídia deixa de estar disponível no servidor.
- Rascunhos e fotos originais locais, com indicação explícita do estado de envio.
- Reprodução interrompida ao sair do story e opção de silenciar.
- Estados de carregamento, erro, acesso negado e story expirado.

Não adicionar sincronização integral do histórico, múltiplas contas locais,
rankings de força, planos pagos ou integrações musicais nesta refatoração.

## Validação manual antes de liberar

1. Abrir as cinco abas de Progresso com histórico vazio e com registros.
2. Criar, editar e excluir uma medida; adicionar foto e abrir em tela cheia.
3. Consultar metas, força, recordes, frequência e cárdio.
4. Abrir Perfil, visualizar conquistas e alterar a opção de áudio.
5. Iniciar treino, registrar e editar séries, ajustar descanso e abrir referências.
6. Finalizar treino e compartilhar o resumo.
7. Reabrir o app e conferir preservação dos dados e integrações no Android.

## Comandos de verificação

```sh
flutter pub get
flutter analyze
flutter test
```

Formatar apenas os arquivos alterados com `dart format`. Se a ferramenta resolver
versões diferentes das do lockfile, não incluir essa atualização nesta mudança.

Os testes Dart não substituem a validação manual de câmera, Health Connect,
overlay, áudio e compartilhamento no dispositivo.
