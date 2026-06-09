import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final apiKey = 'gsk_0U02Xmja' '1UEmgIbrgdUkWGdyb3FYQUYZfpEQGVx0CSYa9Hz0RHIS';
  final rawText = '''
Treino A: Peito, Ombros e Tríceps
Supino Reto (Barra) - 4x10 (Descanso: 120s) - Bilateral
Supino Inclinado (Halteres) - 4x10 (Descanso: 90s) - Bilateral
Desenvolvimento (Halteres) - 3x10 (Descanso: 90s) - Bilateral
Elevação Lateral (Halteres) - 3x12 (Descanso: 60s) - Unilateral
Tríceps Pulley (Polia) - 4x12 (Descanso: 60s) - Bilateral

Treino B: Costas, Bíceps e Posterior de Ombro
Puxada Alta (Polia) - 4x10 (Descanso: 90s) - Bilateral
Remada Baixa (Polia) - 4x10 (Descanso: 90s) - Bilateral
Crucifixo Invertido (Halteres) - 3x12 (Descanso: 60s) - Bilateral
Rosca Direta (Barra) - 4x10 (Descanso: 90s) - Bilateral
Rosca Alternada (Halteres) - 3x12 (Descanso: 60s) - Unilateral

Treino C: Pernas Completas
Agachamento Livre (Barra) - 4x8 (Descanso: 120s) - Bilateral
Leg Press 45 (Máquina) - 4x10 (Descanso: 90s) - Bilateral
Cadeira Extensora (Máquina) - 3x12 (Descanso: 60s) - Bilateral
Mesa Flexora (Máquina) - 4x10 (Descanso: 60s) - Bilateral
Gêmeos em Pé (Máquina) - 4x15 (Descanso: 60s) - Bilateral
''';

  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
  
  const systemPrompt = '''
Você é um assistente especialista em educação física e análise de dados. Seu objetivo é converter um texto livre contendo uma rotina de treinos (que pode estar em português, inglês, etc., copiado do WhatsApp ou anotações) em um objeto JSON válido que descreve a rotina de exercícios.

O JSON gerado DEVE seguir estritamente a seguinte estrutura:
{
  "nome": "Nome do Treino (ex: Hipertrofia)",
  "tipo": "ABC", // Deve ser: "ABC", "ABCD", "ABCDE" ou "CUSTOM"
  "dias": [
    {
      "letra": "A", // "A", "B", "C", "D", "E" sequencialmente
      "nome": "Nome do Dia (ex: Peito e Tríceps)",
      "exercicios": [
        {
          "nome": "Nome do Exercício (ex: Supino Reto)",
          "grupoMuscular": "Peito", // DEVE ser um destes exatos valores: Peito, Costas, Ombro, Tríceps, Bíceps, Perna, Core, Glúteo
          "equipamento": "Barra", // DEVE ser um destes exatos valores: Livre, Barra, Haltere, Cabo, Máquina, Peso Corporal, Smith
          "isUnilateral": false, // true se feito um lado de cada vez, false caso contrário
          "tempoDescansoSegundos": 90, // inteiro (tempo de descanso padrão em segundos)
          "volume": "4x10" // string contendo séries x repetições (ex: "4x10", "3x12", "4x12-10-8")
        }
      ]
    }
  ]
}

Regras Cruciais de Mapeamento:
1. **grupoMuscular**: Escolha rigorosamente um destes: [Peito, Costas, Ombro, Tríceps, Bíceps, Perna, Core, Glúteo].
   - "Elevação Lateral", "Desenvolvimento", "Crucifixo Invertido" e "Posterior de Ombro" devem ser mapeados como "Ombro".
   - "Abdominais" ou "Plancha" devem ser mapeados como "Core".
   - "Agachamento", "Leg Press", "Cadeira Extensora", "Mesa Flexora" e "Panturrilhas/Gêmeos" devem ser mapeados como "Perna".
   - "Elevação de Quadril" / "Glute Bridges" deve ser mapeado como "Glúteo".
2. **equipamento**: Escolha rigorosamente um destes exatos valores: [Livre, Barra, Haltere, Cabo, Máquina, Peso Corporal, Smith].
   - Se o texto indicar "Halteres" (plural) ou "Halter", mapeie obrigatoriamente como "Haltere" (no singular).
   - Se o texto indicar "Polia", "Crossover", "Pulley" ou similar, mapeie obrigatoriamente como "Cabo".
   - Se indicar "Máquina" ou "Polia/Máquina" (como Leg Press, Extensora, Flexora, Gêmeos em Pé na máquina), mapeie como "Máquina".
   - Exercícios com o próprio peso (Flexões de braço, Barra fixa, Abdominais no chão) devem ser "Peso Corporal".
3. **letra**: Comece no "A" e incremente em ordem alfabética ("A", "B", "C"...) para cada dia sequencial de treino.
4. **tipo**: Se a rotina tiver 3 dias, o tipo é "ABC". Se tiver 4 dias, "ABCD". Se tiver 5 dias, "ABCDE". Outros números de dias, coloque "CUSTOM".
5. **Saída**: Retorne APENAS o código JSON puro, sem textos explicativos, saudações ou formatação markdown, apenas o JSON bruto para que eu possa fazer o decode diretamente.
''';

  try {
    print('Sending request to Groq...');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': rawText}
        ],
        'temperature': 0.1,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final content = responseData['choices'][0]['message']['content'] as String;
      print('Response success:');
      print(content);
    } else {
      print('Error response (${response.statusCode}): ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
