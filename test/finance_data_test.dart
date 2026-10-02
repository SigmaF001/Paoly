import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paoly/data/finance_data.dart';
import 'package:paoly/data/pet_data.dart';
import 'package:paoly/models/category.dart';
import 'package:paoly/models/transaction.dart';
import 'package:paoly/models/pet_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FinanceData data;
  late PetData pet;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pet = PetData.detached();
    data = FinanceData(pet: pet);
    await data.load();
    data.seedDefaultAccount();
    await data.flush();
  });
  tearDown(() async {
    await data.flush();
    data.dispose();
  });
  Transaction tx(
    String id,
    double amount, {
    bool expense = false,
    String? categoryId,
  }) => Transaction(
    id: id,
    icon: '💰',
    title: id,
    category: 'เงินเดือน',
    categoryId: categoryId,
    date: DateTime(2026, 10, 2),
    amount: amount,
    isExpense: expense,
    accountId: data.accounts.first.id,
  );

  test(
    'accounts, transactions, balances and custom categories survive reload',
    () async {
      data.setAccountBalance(data.accounts.first.id, 500);
      data.addCategory(
        const TxCategory(
          id: 'custom',
          icon: '🎨',
          nameTh: 'ศิลปะ',
          nameEn: 'Art',
          isExpense: true,
        ),
      );
      data.addTransaction(
        tx('expense', 125.50, expense: true, categoryId: 'custom'),
      );
      await data.flush();
      final restored = FinanceData(pet: PetData.detached());
      await restored.load();
      expect(restored.totalBalance, 374.50);
      expect(restored.transactions.single.amount, 125.50);
      expect(restored.transactions.single.categoryId, 'custom');
      expect(restored.categories.last.nameEn, 'Art');
      restored.dispose();
    },
  );

  test(
    'rapid writes preserve the final snapshot and idempotent rewards',
    () async {
      for (var i = 0; i < 20; i++) {
        data.addTransaction(tx('$i', 10));
      }
      await data.flush();
      final restoredPet = PetData.detached();
      final restored = FinanceData(pet: restoredPet);
      await restored.load();
      expect(restored.transactions.length, 20);
      expect(restored.totalBalance, 200);
      expect(restoredPet.coins, 2);
      await restored.load();
      expect(restoredPet.coins, 2);
      restored.dispose();
    },
  );

  test(
    'delete, Undo and duplicate Undo reconcile both money and coins',
    () async {
      final income = tx('income', 100);
      data.addTransaction(income);
      await data.flush();
      expect(pet.coins, 1);
      data.removeTransaction(income.id);
      await data.flush();
      expect(data.totalBalance, 0);
      expect(pet.coins, 0);
      data.addTransaction(income);
      data.addTransaction(income);
      await data.flush();
      expect(data.transactions.length, 1);
      expect(data.totalBalance, 100);
      expect(pet.coins, 1);
    },
  );

  test(
    'spent rewards cannot be farmed by deleting and readding income',
    () async {
      final income = tx('income', 100);
      data.addTransaction(income);
      await data.flush();
      await pet.buyFood(
        const FoodItem(
          id: 'test',
          emoji: '🍗',
          nameTh: 'อาหาร',
          price: 1,
          restore: 1,
        ),
      );
      data.removeTransaction(income.id);
      await data.flush();
      expect(pet.coins, 0);
      data.addTransaction(income);
      await data.flush();
      expect(pet.coins, 0);
    },
  );

  test('splitting income does not increase rewards', () async {
    data.addTransaction(tx('a', 50));
    await data.flush();
    expect(pet.coins, 0);
    data.addTransaction(tx('b', 50));
    await data.flush();
    expect(pet.coins, 1);
  });

  test(
    'save failure is visible and retry does not duplicate transactions or rewards',
    () async {
      final store = FailingStore();
      SharedPreferencesStorePlatform.instance = store;
      data.addTransaction(tx('income', 100));
      await expectLater(data.flush(), throwsStateError);
      expect(data.saveError, isNotNull);
      expect(pet.coins, 0);
      store.fail = false;
      await data.retrySave();
      expect(data.saveError, isNull);
      expect(data.transactions.length, 1);
      expect(pet.coins, 1);
      await data.retrySave();
      expect(pet.coins, 1);
    },
  );

  test(
    'editing an unsaved retry updates balance and rewards only once',
    () async {
      data.addTransaction(tx('income', 100));
      await data.flush();
      data.updateTransaction(tx('income', 250));
      await data.flush();
      expect(data.transactions.length, 1);
      expect(data.totalBalance, 250);
      expect(pet.coins, 2);
    },
  );

  test('renaming a category keeps transaction identity', () async {
    data.addTransaction(tx('a', 100, categoryId: 'inc_salary'));
    data.updateCategory('inc_salary', nameTh: 'รายได้', nameEn: 'Earnings');
    expect(data.categoryFor(data.transactions.single)?.nameEn, 'Earnings');
  });

  test('invalid amounts and missing accounts cannot enter the ledger', () {
    for (final amount in [double.nan, double.infinity, 0.0, -1.0]) {
      expect(() => data.addTransaction(tx('bad', amount)), throwsArgumentError);
    }
    expect(
      () => data.addTransaction(
        Transaction(
          id: 'bad',
          icon: '',
          title: '',
          category: '',
          date: DateTime.now(),
          amount: 1,
          isExpense: true,
          accountId: 'missing',
        ),
      ),
      throwsArgumentError,
    );
    expect(data.transactions, isEmpty);
  });

  test(
    'invalid persisted data is preserved instead of silently reset',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(FinanceData.storageKey, '{broken');
      final restored = FinanceData(pet: PetData.detached());
      await expectLater(restored.load(), throwsFormatException);
      expect(prefs.getString(FinanceData.storageKey), '{broken');
      restored.dispose();
    },
  );

  test('restart repairs reward write interrupted after finance save', () async {
    data.addTransaction(tx('income', 100));
    await data.flush();
    final prefs = await SharedPreferences.getInstance();
    final stalePet =
        jsonDecode(prefs.getString('pet_state')!) as Map<String, dynamic>;
    stalePet['coins'] = 0;
    stalePet['incomeRewards'] = 0;
    await prefs.setString('pet_state', jsonEncode(stalePet));
    final restoredPet = PetData.detached();
    final restored = FinanceData(pet: restoredPet);
    await restored.load();
    expect(restoredPet.coins, 1);
    restored.dispose();
  });
}

class FailingStore extends InMemorySharedPreferencesStore {
  FailingStore() : super.empty();
  bool fail = true;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (fail) return false;
    return super.setValue(valueType, key, value);
  }
}
