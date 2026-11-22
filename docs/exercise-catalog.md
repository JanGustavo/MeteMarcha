# Catálogo de exercícios e vídeos

A fonte única é `backend/internal/exercisecatalog/catalog.json`, incorporada pelo
servidor e incluída no aplicativo para importação offline. Há 27 exercícios,
sete elegíveis para o mini treino e uma referência inicial de flexão na parede
em português. A disponibilidade e o título desse vídeo foram conferidos pelo
YouTube oEmbed em 22/11/2026; isso não é validação profissional da técnica.
Os outros 26 vídeos aguardam mapeamento.

A IA recebe os nomes permitidos e gera a prescrição. O servidor descarta links e
IDs inventados pelo modelo e atribui `catalogId` e `link` pelo nome/alias e pelo
equipamento do catálogo. Nenhuma busca aproximada associa flexão na parede a
flexão tradicional, ou um agachamento com barra à versão sem peso.

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
