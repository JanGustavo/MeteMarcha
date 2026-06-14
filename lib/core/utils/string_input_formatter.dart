import 'package:flutter/services.dart';

/// Um [TextInputFormatter] reutilizável para entradas de texto.
/// - Filtra e remove qualquer caractere que não seja letra ou espaço.
/// - Garante que o texto contenha apenas caracteres válidos.


class StringInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove caracteres que não sejam letras ou espaços
    String text = newValue.text.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');

    // Mantém a seleção do cursor coerente com o novo texto limpo
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
