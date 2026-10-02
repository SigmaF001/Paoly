import 'package:flutter_test/flutter_test.dart';
import 'package:paoly/utils/formatter.dart';

void main() {
  test('negative balances keep sign outside thousands separators', () {
    expect(formatCurrency(-100), '฿ -100');
    expect(formatCurrency(-123456.78), '฿ -123,456.78');
    expect(formatCurrency(123456.78), '฿ 123,456.78');
  });
}
