# Calistenia, rotinas e conquistas opcionais — 2.14

## Medições

Migração local 16: modalidade e métrica padrão nos exercícios; JSON de métricas
nas execuções. Mantém os registros anteriores sem inferir que eram calistenia.
A configuração pode ser alterada no editor do exercício e durante o treino.
Rotinas podem misturar exercícios das duas modalidades.

O formulário específico registra repetições, segundos ou metros, variação,
assistência, equipamento/objeto e carga externa com origem: nenhuma, medida,
informada, estimada ou desconhecida. Carga estimada/desconhecida exige identificar
o objeto. A carga desconhecida fica nula nos metadados. Não há soma automática do
peso corporal nem conversão de material do objeto em kg.

Os campos numéricos legados ficam em zero nas novas execuções de calistenia por
compatibilidade. Esse zero não é usado como medição de carga: as telas usam os
metadados e esses registros são excluídos de 1RM, volume em kg, alertas de platô e
comparações de carga. A aba Calistenia em Progresso compara somente registros
com a mesma métrica, variação, origem/carga, objeto e assistência. Mostra primeira,
última e melhor marca, sem interpretar mudança de assistência como ganho de força.
Recordes nessa base podem ser compartilhados pelo sistema de conquistas.

Relatórios incluem as métricas e a API valida os campos opcionais. Clientes novos
exibem unidade e origem; clientes antigos ainda recebem a descrição nas observações.
Compartilhamento de rotinas preserva modalidade e métrica padrão.

## Criação e manutenção

Rotina personalizada tem tela própria: nome, quantidade e nomes de dias, busca no
catálogo, ordem dos exercícios e meta opcional. O padrão de modalidade vale para
os próximos exercícios adicionados, permitindo uma divisão mista. Os editores
existentes mantêm edição/exclusão e permitem alterar modalidade e medição. O editor
de exercício preserva a imagem de referência ao salvar outras configurações.
JSON legado `dias/exercicios` é normalizado para o mesmo importador do formato
nativo, evitando perda dos novos campos em caminhos separados.

## Nuvem: cópia explícita, privada por padrão

Migração de API 0009 e endpoints autenticados:

- GET/PUT/DELETE `/v1/me/rewards`: cópia privada das conquistas e do destaque.
- GET `/v1/members/{userID}/showcase`: somente o destaque, se autorizado e houver
  associação atual a algum squad em comum. Não expõe o restante do histórico.

O aplicativo só envia quando o usuário escolhe Enviar cópia para a nuvem.
Restaurar combina identificadores e preserva registros locais. Atualizações
posteriores exigem novo envio; não é sincronização automática de treinos ou
conquistas. Remover a cópia apaga o destaque online, sem apagar os dados locais
nem revogar stories publicados anteriormente. Nenhuma fotografia é enviada por
esse fluxo. O usuário pode autorizar o destaque aos squads; a autorização é
verificada em cada leitura e desaparece ao sair do grupo. A API identifica os
registros como informados pelo cliente, sem verificação esportiva ou ranking.

O compartilhamento de conquistas pelo perfil continua abrindo o editor de story
com imagem/legenda, e requer confirmação para publicar. A tela de conquistas
concentra também os controles da cópia online; os membros do squad podem tocar
no participante para consultar um destaque disponibilizado.
