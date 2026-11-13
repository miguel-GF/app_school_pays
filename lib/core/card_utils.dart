import 'package:flutter/services.dart';

String onlyDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

/// Validación de Luhn para números de tarjeta.
bool luhnValid(String input) {
  final digits = onlyDigits(input);
  if (digits.length < 13 || digits.length > 19) {
    return false;
  }
  var sum = 0;
  var doubleIt = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var d = int.parse(digits[i]);
    if (doubleIt) {
      d *= 2;
      if (d > 9) {
        d -= 9;
      }
    }
    sum += d;
    doubleIt = !doubleIt;
  }
  return sum % 10 == 0;
}

/// Marca según los primeros dígitos.
String detectBrand(String input) {
  final digits = onlyDigits(input);
  if (digits.isEmpty) {
    return 'Tarjeta';
  }
  if (digits.startsWith('4')) {
    return 'Visa';
  }
  if (digits.startsWith('34') || digits.startsWith('37')) {
    return 'American Express';
  }
  if (digits.length >= 2) {
    final two = int.parse(digits.substring(0, 2));
    if (two >= 51 && two <= 55) {
      return 'Mastercard';
    }
  }
  if (digits.length >= 4) {
    final four = int.parse(digits.substring(0, 4));
    if (four >= 2221 && four <= 2720) {
      return 'Mastercard';
    }
  }
  return 'Tarjeta';
}

/// Devuelve null si la vigencia "MM/AA" es válida y no ha vencido.
String? validateExpiry(String input, DateTime now) {
  final digits = onlyDigits(input);
  if (digits.length != 4) {
    return 'Usa el formato MM/AA';
  }
  final month = int.parse(digits.substring(0, 2));
  final year = 2000 + int.parse(digits.substring(2, 4));
  if (month < 1 || month > 12) {
    return 'Mes inválido';
  }
  final expired =
      year < now.year || (year == now.year && month < now.month);
  if (expired) {
    return 'La tarjeta está vencida';
  }
  return null;
}

/// Agrupa el número de tarjeta en bloques de 4 mientras se escribe.
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = onlyDigits(newValue.text);
    if (digits.length > 16) {
      digits = digits.substring(0, 16);
    }
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buf.write(' ');
      }
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Da formato MM/AA mientras se escribe.
class ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = onlyDigits(newValue.text);
    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }
    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
