import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paoly/data/app_settings.dart';
import 'package:paoly/data/finance_data.dart';
import 'package:paoly/data/pet_data.dart';
import 'package:paoly/models/transaction.dart';
import 'package:paoly/screens/transactions_screen.dart';
import 'package:paoly/screens/reports_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FinanceData data;
  late AppSettings settings;
  Future<void> initialize() async {
    SharedPreferences.setMockInitialValues({'lang_code': 'en'});
    settings = AppSettings();
    await settings.load();
    data = FinanceData(pet: PetData.detached());
    await data.load();
    data.seedDefaultAccount();
    data.addTransaction(
      Transaction(
        id: 'expense',
        icon: '🍔',
        title: 'Lunch',
        category: 'อาหาร',
        categoryId: 'exp_food',
        date: DateTime.now(),
        amount: 100,
        isExpense: true,
        accountId: data.accounts.first.id,
      ),
    );
    await data.flush();
  }

  testWidgets(
    'cancel deletion preserves transaction; confirm and Undo restore balance',
    (tester) async {
      await initialize();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionsScreen(data: data, settings: settings),
          ),
        ),
      );
      await tester.drag(find.byType(Dismissible), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete this transaction?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(data.transactions.length, 1);
      await tester.drag(find.byType(Dismissible), const Offset(-700, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(data.transactions, isEmpty);
      expect(data.totalBalance, 0);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(data.transactions.length, 1);
      expect(data.totalBalance, -100);
      await data.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      data.dispose();
    },
  );

  testWidgets('reports resolve renamed category in the active language', (
    tester,
  ) async {
    await initialize();
    data.updateCategory('exp_food', nameEn: 'Meals');
    await data.flush();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsScreen(data: data, settings: settings),
        ),
      ),
    );
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('อาหาร'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    data.dispose();
  });
}
