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

    final settings = AppSettings(persistent: true);
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

  testWidgets('Dashboard adapts to narrow and wide windows', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'user_name': 'A very long account holder name',
      'lang_code': 'en',
    });

    final settings = AppSettings(persistent: true);
    await settings.load();
    final data = FinanceData();
    await data.load();
    data.seedDefaultAccount();
    data.addAccount('Long named savings account');
    data.setAccountBalance(data.accounts.first.id, 987654321.99);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpWidget(PaolyApp(data: data, settings: settings));
    await tester.pump();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    data.dispose();
  });
}
