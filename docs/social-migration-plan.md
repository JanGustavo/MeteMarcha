# Expansão social do MeteMarcha

## Produto e linguagem

**Cohorts** é o nome proposto para os grupos no app: é curto, em inglês e remete
a uma turma que progride junta. O código e a API continuam usando `groups`;
trocar os textos da interface não exige migrar os IDs existentes.

Cada Cohort é privada, tem no máximo dez integrantes e uma pessoa pode participar
de várias. O grupo selecionado define o feed, convites e rankings exibidos. Criar
ou entrar em um grupo o seleciona; ao sair do grupo selecionado, o app seleciona
outro de que a pessoa participe. Entrar em um grupo nunca concede acesso a dados
de outro.

## Publicações e música

- A pessoa pode fotografar, guardar um rascunho local e publicar antes, durante ou
  depois do treino. Publicar não conclui uma sessão de treino.
- Uma publicação pode ter várias fotos ordenadas, legenda e um trecho opcional do
  catálogo de áudio autorizado, reproduzido dentro do app. O limite de fotos e o
  tamanho total serão definidos no contrato do upload antes da implementação.
- O mesmo conjunto de stories aparece no feed vertical e na faixa horizontal de
  círculos agrupados por autor. Ambas as apresentações deixam de mostrar o story
  exatamente 24 horas após a publicação. O servidor atual permite ao autor
  recuperar sua foto até 72 horas; esse prazo de recuperação não prolonga a
  exibição no grupo.
- Reações são uma por pessoa por story. O app permite trocar ou remover a reação.
- O áudio para quando a pessoa sai do story; há opção de silenciar.

## Rankings e medidas

Os rankings são calculados por Cohort e por período explícito. **Evolução usa o
ponto de partida e a meta da própria pessoa**. Valores brutos também são mostrados
e podem ser comparados entre integrantes que registraram a mesma medida, na mesma
unidade. O app deve pedir uma ação explícita para compartilhar medidas com o
grupo; históricos locais anteriores não são publicados automaticamente.

Para uma meta de aumento, com `início = 60 kg`, `atual = 66 kg`, `meta = 70 kg`:

- Mudança desde o início: `(66 - 60) / 60 × 100 = +10%`.
- Caminho até a meta: `(66 - 60) / (70 - 60) × 100 = 60%`.
- Medida bruta atual: `66 kg` (e o grupo pode comparar esse número com os de outros
  integrantes que compartilharam peso).

Para metas de redução, o avanço é `(início - atual) / (início - meta) × 100`;
para metas de aumento, `(atual - início) / (meta - início) × 100`. O valor pode
ser negativo ou ultrapassar 100%; a interface o mostra sem esconder regressão ou
superação da meta. Sem meta válida (`meta = início`), não há porcentagem de avanço.
Sem medida inicial positiva, não há porcentagem de mudança desde o início.

O ranking de evolução **não mistura quilogramas, centímetros e cargas** numa só
pontuação bruta. A tela oferece: avanço percentual rumo à meta individual e
comparações brutas filtradas por tipo de medida e unidade. Para força, comparar
somente registros do mesmo exercício padronizado, equipamento e critério de carga.
Para consistência, usar treinos concluídos por semana divididos pela meta semanal
da própria pessoa, com regra explícita para semanas incompletas e registros
duplicados. Alertas de competição mostram o motivo e permitem desligá-los.

## Sincronização e notificações

O histórico de treinos, medidas, metas e fotos locais deve sincronizar entre
aparelhos depois de vincular o perfil local a uma conta. Cada registro precisa de
ID estável no cliente, revisão do servidor, data de alteração e marca de exclusão.
O app mantém uma fila de mudanças para o uso offline e reenvia com chave
idempotente. Conflitos exigem regra por entidade: por exemplo, séries de treino
editadas em dois aparelhos não podem ser sobrescritas silenciosamente. A migração
inicial deve permitir revisar o que será enviado e evitar duplicar dados ao
vincular perfis. Mídias sincronizadas exigem quota, retenção e backup próprios.

Notificações de novos posts precisam de permissão do sistema e preferências por
Cohort. Não enviar alerta para o próprio post; agrupar notificações para evitar
excesso. O conteúdo da notificação não deve expor medidas ou fotos na tela
bloqueada.

## Entregas verificáveis

| Etapa | Resultado observável | Dependência principal |
| --- | --- | --- |
| 1. Base do servidor | Cadastro, login, convites, limite de dez, story de uma foto, catálogo e reações | Backend piloto, PR #3 |
| 2. Vários Cohorts | Listar, criar, entrar, selecionar e sair; feed isolado por grupo | Etapa 1 |
| 3. App social | Login/vínculo, rascunho, feed e círculos, player e estados de envio | Contrato das etapas 1–2 |
| 4. Publicação ampliada | Várias fotos ordenadas e exclusão de publicação | Etapa 3, storage de mídia |
| 5. Evolução e rankings | Metas individuais, medidas brutas compartilhadas, consistência e força padronizada | Modelo de medidas e consentimento |
| 6. Alertas e notificações | Preferências por grupo e entrega de novos posts | Etapas 3–5 |
| 7. Histórico entre aparelhos | Envio inicial, alterações offline, conflitos, exclusões e recuperação | Identidade estável dos registros |
| 8. VPS e liberação | HTTPS, backup/restauração, monitoramento e teste em aparelhos reais | Cada etapa de servidor pronta |

Cada etapa deve ter testes de acesso entre grupos, migração de banco existente e
comportamento offline/expiração quando pertinente. A implantação na VPS exige
domínio, acesso à máquina, arquivos de música autorizados e estratégia de backup.

## Estado em novembro de 2026

O backend piloto da etapa 1 está em PR separado e ainda não foi implantado. A
etapa 2 começa nesta branch. Os itens posteriores são escopo aceito do produto,
mas ainda não são funcionalidades implementadas.
