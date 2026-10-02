import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:paoly/main.dart';
import 'package:paoly/data/app_settings.dart';
import 'package:paoly/data/finance_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Dashboard renders smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'user_name': 'Test',
      'lang_code': 'th',
    });

    final settings = AppSettings();
    await settings.load();

    final data = FinanceData();
    await data.load();
    data.seedDefaultAccount();
    data.setAccountBalance(data.accounts.first.id, 48320.50);
    await data.flush();
    await tester.pumpWidget(PaolyApp(data: data, settings: settings));
    await tester.pump();

    expect(find.text('ภาพรวมการเงิน'), findsOneWidget);
    expect(find.text('฿ 48,320.50'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox.shrink());
    data.dispose();
  });
}
