# Consistência e conquistas — 2.13

A regra escolhida é uma semana ativa com pelo menos um treino concluído.
Treinar três ou seis vezes vale a mesma semana. O intervalo vai de segunda a
domingo, no horário local do dispositivo. Sessões futuras são ignoradas;
sessões repetidas no mesmo dia não duplicam o indicador de dias treinados.

O contador anterior dependia da meta da agenda atual, aplicada também ao
histórico. A nova regra é independente da agenda. A semana atual não quebra
a sequência antes de terminar: se não houve treino nela, a sequência é contada
até a semana anterior. Há sequência atual, melhor histórico e total de semanas
ativas separados. O cálculo não usa a antiga chave ISO baseada no ano civil,
e trata semanas que atravessam dezembro/janeiro pelas datas das segundas-feiras.

Os marcos são 1, 3, 6, 10, 12, 20, 30 e 52 semanas consecutivas. As conquistas
recebem registros persistentes em SharedPreferences, com identificador estável,
valor, texto, data de registro, estado visto/não visto e destaque do perfil.
Um marco conquistado não é removido por pausa posterior. A importação de um
histórico que cruza vários marcos apresenta apenas o maior novo marco; os outros
ficam disponíveis na lista. Escritas concorrentes são serializadas.

A tela Consistência e conquistas abre pelo contador de semanas, pelo sino da
home e pela vitrine do perfil. O contador tem animação de entrada, sem o antigo
tremor ao zerar. Marcos novos usam uma celebração que sobe da parte inferior,
com medalha vetorial e partículas de duração limitada. Ela espera a volta ao
início para não sobrepor a finalização de um treino. Acessibilidade com movimento
reduzido desliga as partículas e o movimento interno. O usuário fecha a
celebração, que não desaparece por um temporizador de quatro segundos.

Recordes pessoais usam o mesmo fluxo, substituindo o snackbar colorido. O texto
identifica a estimativa de 1RM e a execução registrada; não apresenta a estimativa
como medição direta. Desbloqueios das demais conquistas são guardados e usam a
mesma celebração. O fluxo de finalização lê os dados concluídos antes de comparar
níveis, em vez de depender de um atraso fixo de 250 ms.

Compartilhar cria uma imagem PNG de 720×720. No squad, abre o editor existente
com a imagem e uma legenda de até 300 caracteres: publicar continua sendo uma
ação explícita do usuário e o story tem a validade normal de 24 horas. Também
é possível usar o compartilhamento do sistema e destacar uma conquista no perfil.
Essas conquistas e o destaque são locais ao aparelho, como o histórico atual;
não há nova sincronização entre dispositivos nem validação de recordes pelo
servidor. O compartilhamento usa a API de stories já existente, sem migração do
backend ou dados simulados no produto.
