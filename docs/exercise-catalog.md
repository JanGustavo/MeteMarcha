# Catálogo de exercícios e vídeos

A fonte única é `backend/internal/exercisecatalog/catalog.json`, incorporada pelo
servidor e incluída no aplicativo para importação offline. Há 27 exercícios,
sete elegíveis para o mini treino e 26 vídeos associados. Todas as sete opções
do mini treino têm referência. Os metadados e a disponibilidade foram conferidos
pelo YouTube oEmbed em 22/11/2026; isso não é validação profissional da técnica
nem garantia de reprodução em cada dispositivo.

O mapeamento fornecido em `exercise_youtube_map_ptbr.csv` foi normalizado em
`docs/exercise-video-mapping.csv`. A pesquisa original, com uma vírgula escapada
no título do afundo, está em `docs/exercise-video-research.csv`. Os resultados
da consulta oficial estão em `docs/exercise-video-checks.json`. Títulos e canais
do catálogo usam os metadados retornados pelo YouTube; o idioma informado pela
pesquisa foi preservado, pois o oEmbed não informa idioma do áudio.

Puxada frontal permanece sem referência: o link enviado (`YywSCu4Y360`) retornou
HTTP 401 no oEmbed. O exercício continua disponível e o link foi preservado na
pesquisa, sem ser associado automaticamente. Uma alternativa precisa ser
confirmada antes de incluí-la. Anotações da pesquisa são proveniência, não
instruções nem regras de seleção do aplicativo.

A IA recebe os nomes permitidos e gera a prescrição. O servidor descarta links e
IDs inventados pelo modelo e atribui `catalogId` e `link` pelo nome/alias e pelo
equipamento do catálogo. Nenhuma busca aproximada associa flexão na parede a
flexão tradicional, ou um agachamento com barra à versão sem peso.

Na versão 2.11.3, nomes comuns como Prancha e Flexão de braço também são aliases.
Para movimentos reconhecidos de peso corporal, Livre é tratado como rótulo
genérico da importação, assim como Sem equipamento ou Peso do corpo. Barra fixa
aceita Peso Corporal quando a barra é o apoio. Equipamentos incompatíveis e
variações não cadastradas continuam sem associação automática.

Ao carregar os exercícios de um dia já salvo, referências ausentes reconhecidas
são preenchidas no banco. A atualização altera apenas o link e protege uma
referência manual adicionada entre a leitura e a gravação. Séries, descanso,
equipamento e histórico permanecem intactos. A home indica quantos exercícios
têm vídeo, e a lista do dia e o card durante o treino oferecem o botão do player.
A importação informa a cobertura, inclusive quando há exercícios sem vídeo.

Na importação JSON, uma referência explícita do arquivo tem prioridade. Se não
houver link, o catálogo complementa o exercício reconhecido. Quando a referência
difere de um exercício já salvo, a importação cria outro registro em vez de
alterar os treinos antigos. O link é preservado no compartilhamento e aberto no
player interno existente. Exercícios sem vídeo continuam funcionando.

## Mapeamento para humanos ou outro agente

Preencha `docs/exercise-video-mapping.csv`, preservando IDs, nomes e equipamentos.
Priorize português; aceite outro idioma se não houver uma boa demonstração em
português. Para cada variação, procure um vídeo específico, público, de execução
clara, de um profissional/canal identificável. Registre URL, idioma e canal.
Não use vídeos gerais de divisão de treino como demonstração de um exercício.
Confira manualmente se o vídeo corresponde à variação e se permite incorporação.
Não baixe ou redistribua vídeos; o aplicativo usa o player do YouTube.

`python3 scripts/import_exercise_videos.py docs/exercise-video-mapping.csv`
valida a planilha. Com `--write`, aplica os links ao JSON compartilhado. Células
vazias não removem links existentes. Depois execute os testes e publique uma
nova API e versão do aplicativo para distribuir o catálogo atualizado.

## Fotos, calendário e player

O story com vídeo usa uma única área de mídia: a miniatura é substituída pelo
player no mesmo espaço. Não exibe a capa estática gerada acima do vídeo.

Após capturar foto, o aplicativo oferece prévia com espelhamento, inicialmente
ligado ao solicitar câmera frontal. O usuário pode desligar se o aparelho já
espelhar ou se trocar para a câmera traseira. A foto salva recebe a inversão nos
pixels; a galeria não é invertida automaticamente.

A foto do dia não substitui os indicadores do calendário. A consistência na home
continua com marcações de conclusão, e o calendário mensal com números e cores
do treino e detalhes ao tocar. As letras A/B/C permanecem na identificação dos
dias de treino. Não são usadas fotos dentro das células pequenas.

## Capas das divisões (2.11.3)

As capas abstratas foram substituídas por cenas fotográficas geradas para o app,
em painéis quadrados de peito, costas, pernas, ombros e braços. As divisões ABC,
ABCD e ABCDE usam respectivamente três, quatro e cinco painéis. O personalizado
inclui uma flexão na parede. Os arquivos WebP em `assets/images/workout_photos/`
somam aproximadamente 100 KB; as quatro capas antigas foram removidas.
São ilustrações de seleção, não fotografias de usuários nem instruções técnicas.
