import 'package:flutter/services.dart';

/// Um [TextInputFormatter] reutilizável para entradas numéricas decimais.
/// - Substitui automaticamente vírgulas por pontos.
/// - Filtra e remove qualquer caractere não-numérico (letras, símbolos).
/// - Garante que exista no máximo um ponto decimal.
/// - Se colado um texto completamente não-numérico (ex: "dez"), limpa o campo (retorna vazio).
class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Se o valor inserido/colado não contiver nenhum dígito numérico, limpa o campo
    final hasDigits = newValue.text.contains(RegExp(r'\d'));
    if (!hasDigits) {
      return TextEditingValue.empty;
    }

    // 1. Substitui vírgulas por pontos
    String text = newValue.text.replaceAll(',', '.');

    // 2. Remove caracteres que não sejam dígitos ou pontos
    text = text.replaceAll(RegExp(r'[^0-9.]'), '');

    // 3. Garante que haja apenas um ponto decimal no máximo
    final parts = text.split('.');
    if (parts.length > 2) {
      text = '${parts[0]}.${parts.sublist(1).join('')}';
    }

    // Mantém a seleção do cursor coerente com o novo texto limpo
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

