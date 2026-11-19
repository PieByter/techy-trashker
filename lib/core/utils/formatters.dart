const _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatShortDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String formatWeight(double kg) {
  final value = kg.toStringAsFixed(1).replaceAll('.', ',');
  return '$value kg';
}

String formatPoints(int points) {
  final raw = points.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
    buffer.write(raw[i]);
  }
  return buffer.toString();
}
