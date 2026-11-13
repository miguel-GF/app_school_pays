const List<String> _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// 2000.5 -> "$2,000.50"
String formatMoney(double amount) {
  final negative = amount < 0;
  final cents = (amount.abs() * 100).round();
  final whole = (cents ~/ 100).toString();
  final frac = (cents % 100).toString().padLeft(2, '0');
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) {
      buf.write(',');
    }
    buf.write(whole[i]);
  }
  final sign = negative ? '-' : '';
  return '$sign\$${buf.toString()}.$frac';
}

/// "5 nov 2026"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "5 nov 2026, 14:07"
String formatDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${formatDate(d)}, $hh:$mm';
}
