import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paoly/data/app_settings.dart';
import 'package:paoly/data/finance_data.dart';
import 'package:paoly/data/pet_data.dart';
import 'package:paoly/models/transaction.dart';
import 'package:paoly/services/finance_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'guest finance, name and pet never persist or load legacy personal data',
    () async {
      SharedPreferences.setMockInitialValues({
        'finance_state_v1': '{legacy}',
        'user_name': 'Legacy user',
        'onboarded': true,
        'pet_state': '{legacy pet}',
      });
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final settings = AppSettings();
      await settings.load();
      expect(settings.userName, isEmpty);
      expect(settings.isFirstLaunch, isTrue);
      await settings.completeOnboarding('Guest');
      final pet = PetData.detached();
      final data = FinanceData(pet: pet);
      await data.load();
      data.seedDefaultAccount();
      data.addTransaction(
        Transaction(
          id: '1',
          icon: '',
          title: 'Income',
          category: '',
          date: DateTime.now(),
          amount: 200,
          isExpense: false,
          accountId: data.accounts.first.id,
        ),
      );
      await data.flush();
      await pet.choosePet('test', 'Guest dog');
      expect(data.totalBalance, 200);
      expect(pet.coins, 2);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      final restarted = FinanceData(pet: PetData.detached());
      await restarted.load();
      expect(restarted.transactions, isEmpty);
      expect(restarted.accounts, isEmpty);
      data.dispose();
      restarted.dispose();
      settings.dispose();
    },
  );

  test(
    'failed cloud saves retain edits and retry without duplication',
    () async {
      final store = _TestStore();
      final data = FinanceData(store: store, pet: PetData.detached());
      await data.load();
      store.fail = true;
      data.seedDefaultAccount();
      await expectLater(data.flush(), throwsStateError);
      expect(data.accounts, hasLength(1));
      store.fail = false;
      await data.retrySave();
      final restored = FinanceData(store: store, pet: PetData.detached());
      await restored.load();
      expect(restored.accounts, hasLength(1));
      expect(data.saveError, isNull);
      restored.dispose();
      data.dispose();
    },
  );

  test(
    'separate account stores never inherit guest or another account data',
    () async {
      final firstStore = _TestStore();
      final a = FinanceData(store: firstStore, pet: PetData.detached());
      a.addAccount('A');
      await a.flush();
      final b = FinanceData(store: _TestStore(), pet: PetData.detached());
      await b.load();
      expect(b.accounts, isEmpty);
      final guest = FinanceData(pet: PetData.detached());
      await guest.load();
      expect(guest.accounts, isEmpty);
      final restoredA = FinanceData(store: firstStore, pet: PetData.detached());
      await restoredA.load();
      expect(restoredA.accounts.single.name, 'A');
      a.dispose();
      b.dispose();
      guest.dispose();
      restoredA.dispose();
    },
  );
}

class _TestStore implements FinanceStore {
  String? snapshot;
  bool fail = false;
  @override
  Future<String?> read() async => snapshot;
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('Offline');
    snapshot = value;
  }
}
