const _thaiMonths = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

const _enMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatCurrency(double amount) {
  final str = amount.toStringAsFixed(2);
  final parts = str.split('.');
  final intPart = parts[0];
  final decPart = parts[1];

  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }

  return decPart == '00' ? '฿ $buf' : '฿ $buf.$decPart';
}

String formatDate(DateTime date, {String langCode = 'th'}) {
  final months = langCode == 'th' ? _thaiMonths : _enMonths;
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
