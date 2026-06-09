# Correções / Issues

## Resumo

Lista de bugs e melhorias relatadas para o app.

## Itens

1. Erro de rede ao formatar entrada

	- Mensagem: `ClientException with SocketException: Failed host lookup: 'api.groq.com' (OS Error: No address associated with hostname, errno = 7)`
	- Endpoint afetado: `https://api.groq.com/openai/v1/chat/completions`

2. Séries unilaterais tratadas separadamente

	- Registros das séries unilateral esquerda e direita são tratados como entidades distintas em vez de pertencerem ao mesmo exercício/conjunto.

3. Mensagem "próxima série" sem toggle de fechamento

	- Ao ajustar o número de séries esperadas no último exercício, aparece uma mensagem de "próxima série" que não possui um botão/toggle para fechar.

4. Som de fim de descanso para música dentro do app

	- Implementar ou corrigir o som que toca ao final do descanso quando o áudio do app está ativo.

5. Contagem fora do app presa na notificação

	- O contador exibido na notificação externa fica preso em um valor pequeno e não dispara som nem para corretamente ao finalizar.

6. Diferenciação de aparelhos / variações de barras

	- Falta distinguir entre barra grande e barra pequena; adicionar variações (ex.: "triângulo") como equipamentos selecionáveis.

7. Campo de observações avançadas

	- Adicionar suporte a observações por série/exercício (ex.: banco 80°, rest-pause, drop set).

8. Suspeita de relógio sumindo / falha na contagem de descanso

	- Investigar casos em que o cronômetro desaparece ou a contagem regressiva do descanso falha.

---


