import 'package:flutter_test/flutter_test.dart';
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

    await tester.pumpWidget(PaolyApp(data: FinanceData(), settings: settings));
    await tester.pump();

    expect(find.text('ภาพรวมการเงิน'), findsOneWidget);
    expect(find.text('฿ 48,320.50'), findsOneWidget);
  });
}
