# 🏋️ Mete Marcha

> **Treine. Registre. Evolua.** O companheiro ideal para planejar seus treinos, aplicar a sobrecarga progressiva e acompanhar seus resultados de forma ágil e sem distrações. ⚡

---

## 📦 Download da Versão Mais Recente

[![Download APK](https://img.shields.io/badge/Download-APK%20Release-red?style=for-the-badge&logo=android)](https://github.com/JanGustavo/MeteMachaFit/releases/latest)

> [!TIP]
> Clique no botão acima para baixar a versão mais recente diretamente da página de Releases do GitHub e começar a registrar sua evolução hoje mesmo!

---

## 🎯 Por que "Mete Marcha"?

A evolução real na musculação baseia-se no princípio da **sobrecarga progressiva**. Para que o músculo hipertrofie ou ganhe força, ele precisa ser submetido a estímulos gradualmente maiores (seja em carga, repetições ou volume de treino) ao longo do tempo.

No entanto, **muitas pessoas treinam sem registrar sua rotina e acabam por não ver sua evolução**. Sem saber exatamente quanta carga levantou ou quantas repetições realizou no treino anterior, você treina "às cegas", confiando apenas na memória e correndo o risco de estagnar.

O **Mete Marcha** nasceu para resolver isso: um aplicativo focado em simplicidade, agilidade e estética premium, onde você registra cada série em tempo real.

"Mete Marcha" é uma expressão popular brasileira de incentivo para ir em frente, agir com atitude e fazer acontecer. É o empurrão que você precisa para ir à academia, registrar seus treinos e evoluir constantemente!

---

## 🚀 Funcionalidades Principais (Features)

### 🆕 Novas Implementações & Melhorias Recentes

* **✏️ Edição e Exclusão de Séries**: Se você registrou uma série errada ou quer ajustar peso/repetições, basta tocar na série salva para editá-la ou excluí-la. O aplicativo re-sequencia automaticamente as séries subsequentes no banco de dados e recalcula o seu histórico/1RM em tempo real.
* **🏆 Níveis de Força (Iniciante a Elite)**: Um painel interativo que exibe o seu nível de força estimado por exercício com base na fórmula de 1RM máximo e detalha as faixas de força necessárias para alcançar cada nível.
* **💪 Suporte Completo a Exercícios Unilaterais**: Registro facilitado de execuções com pernas ou braços isolados (Esquerdo/Direito), com controle de peso e repetições independentes sob uma mesma série.
* **⚡ Tratamento Inteligente de Entrada**: Bloqueio completo de textos não-numéricos nos campos de carga e repetições (via `DecimalInputFormatter`), evitando que ações de colar corrompam os inputs.
* **🎨 UX Aprimorada de Exercícios Pendentes**: Interface melhorada e dinâmica com status visual premium para você saber exatamente o que ainda falta treinar no dia.
* **🖼️ Imagens de Treino Temáticas**: Fotos e ilustrações contextualizadas com musculação e treinos nas rotinas (evitando placeholders ou widgets genéricos).

### ⚙️ Funcionalidades Base

* **📊 Divisões de Treino Pré-configuradas**: Suporte a rotinas automáticas como **ABC**, **ABCD**, **ABCDE** e treinos totalmente customizados pelo usuário.
* **📅 Agenda Semanal Dinâmica**: Organização de treinos a partir de segunda-feira com lembretes inteligentes.
* **🎛️ Calculadora de Anilhas Integrada**: Descubra de forma rápida como montar a barra com o peso desejado.
* **⏱️ Cronômetro de Descanso**: Cronômetro de descanso integrado com bipe sonoro para manter a intensidade do treino sob controle.
* **📈 Histórico e Gráficos de Evolução**: Gráficos dinâmicos que mostram o ganho de carga, volume e peso corporal ao longo do tempo.
* **🔒 Banco de Dados Local Seguro**: Persistência offline total e segura usando **SQLite** via Drift para Android e Web.

---

## 🏛️ Histórico de Desenvolvimento e Arquitetura

O projeto foi iniciado a partir das seguintes diretrizes e arquitetura sugerida:

### Stack Inicial Sugerida

* **Framework**: Flutter
* **Banco de Dados**: SQLite (com Drift para compatibilidade Web/Android)
* **Gerência de Estado**: Riverpod & Streams reativas
* **Gráficos**: `fl_chart`
* **Áudio**: Bipe e comemorações PR

### Estrutura de Diretórios

```text
lib/
│
├── main.dart
│
├── core/
│   ├── database/
│   ├── services/
│   └── theme/
│
├── models/
│   ├── exercise.dart
│   ├── workout.dart
│   ├── workout_log.dart
│   └── user_profile.dart
│
├── pages/
│   ├── splash/
│   ├── home/
│   ├── setup/
│   ├── workout/
│   ├── progress/
│   └── profile/
│
└── widgets/
```

### Schema de Banco de Dados de Referência

* **Tabela de Exercícios**: `id`, `nome`, `link`, `grupo_muscular`, `is_unilateral`, `equipamento`, `vezes_feito`.
* **Tabela de Logs de Exercício**: `id`, `exercise_id`, `workout_session_id`, `data`, `peso`, `repeticoes`, `lado` (ambos / esquerdo / direito), `concluido` (0=pulado, 1=feito), `serie`.
* **Tabela de Perfil do Usuário**: `id`, `peso_atual`, `altura`.
* **Tabela de Peso Semanal**: `id`, `semana`, `peso`.
