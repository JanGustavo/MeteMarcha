# Expansão para calistenia

A escolha inicial de foco (Academia/Musculação ou Calistenia), a alteração pelo
perfil e o mini treino por IA com recursos disponíveis foram implementados.
A versão 2.14 acrescenta unidades por execução, origem da carga, objeto e assistência;
veja `calisthenics-cloud-migration.md`. O cadastro dedicado de equipamentos pessoais
e progressões automáticas de variação continuam como expansão.

## Entrada e navegação

No primeiro cadastro de perfil, oferecer Academia e Calistenia. A escolha define
os exemplos e o catálogo inicial, e pode ser alterada depois. Preservar o histórico
existente e permitir dias de treino de modalidades diferentes na mesma conta.
Usuários atuais continuam com sua configuração, sem refazer o cadastro.

## Como registrar uma execução

Separar a forma de execução da carga externa:

- Modalidade: academia ou calistenia, registrada na sessão.
- Exercício e variação: flexão, flexão inclinada, barra assistida, barra livre etc.
- Tipo de medida: repetições, tempo de sustentação ou distância.
- Carga externa em kg: opcional; valor desconhecido deve ser nulo, não zero.
- Origem da carga: medida em balança, estimada, informada no equipamento ou desconhecida.
- Equipamento: mochila, pacote, halter, peso artesanal, elástico etc.
- Identificação do objeto: nome reutilizável, por exemplo “mochila azul”, permitindo
  comparar execuções com o mesmo objeto sem afirmar um peso exato.
- Assistência: manter separada da carga adicional, incluindo o tipo de elástico.
- Peso corporal: dado de contexto opcional, sem somá-lo automaticamente à carga externa.

Exemplos:

| Registro | Como apresentar |
| --- | --- |
| Mochila pesada na balança: 6,2 kg | 6,2 kg · medida |
| Pacotes de alimento usados como referência | ≈ 2 kg · estimada; observação dos pacotes |
| Peso artesanal sem pesagem | Carga desconhecida · peso artesanal A |
| Prancha | Tempo em segundos |
| Barra com elástico | Repetições + tipo de assistência |

A massa de um objeto não deve ser calculada apenas por ser de gesso, concreto
ou cerâmica. Se não houver pesagem, conservar o registro como estimado ou desconhecido.

## Progresso

Comparar a própria evolução dentro da mesma variação, equipamento, assistência e
forma de medição. Destacar mais repetições, maior tempo, menor assistência ou
mudança de variação. Não converter automaticamente dificuldade técnica em quilos.
Carga estimada deve permanecer identificada nos gráficos e relatórios.
Volume em kg × repetições só deve aparecer quando a carga externa for conhecida,
com a origem preservada. Não tratar carga desconhecida como zero nem misturar
resultados com bases de medição diferentes em um ranking de força.

## Compatibilidade e etapas

1. Migração aditiva: manter campos e sessões atuais; acrescentar modalidade e
   tipo de medida. Tratar cargas antigas como informadas, sem presumir pesagem.
2. Entrada Academia/Calistenia e catálogo de variações, com troca pelo perfil.
3. Formulários por repetições/tempo e cadastro de equipamento pessoal com origem da carga.
4. Relatórios e stories com unidade e indicação de estimativa.
5. Gráficos comparáveis e metas individuais, antes de expandir rankings.

Não inferir automaticamente uma redução de assistência ou troca de variação como
um percentual de ganho de força. Preservar os dados originais de cada execução.
