import 'dart:convert';
import '../services/finance_store.dart';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'pet_data.dart';

const List<TxCategory> _defaultCategories = [
  TxCategory(
    id: 'exp_food',
    icon: '🍔',
    nameTh: 'อาหาร',
    nameEn: 'Food',
    isExpense: true,
    isDefault: true,
  ),
  TxCategory(
    id: 'exp_travel',
    icon: '🚗',
    nameTh: 'เดินทาง',
    nameEn: 'Transport',
    isExpense: true,
    isDefault: true,
  ),
  TxCategory(
    id: 'exp_shopping',
    icon: '🛍️',
    nameTh: 'ช้อปปิ้ง',
    nameEn: 'Shopping',
    isExpense: true,
    isDefault: true,
  ),
  TxCategory(
    id: 'exp_entertain',
    icon: '🎮',
    nameTh: 'บันเทิง',
    nameEn: 'Entertainment',
    isExpense: true,
    isDefault: true,
  ),
  TxCategory(
    id: 'exp_util',
    icon: '💡',
    nameTh: 'ค่าไฟ/น้ำ',
    nameEn: 'Utilities',
    isExpense: true,
    isDefault: true,
  ),
  TxCategory(
    id: 'exp_health',
    icon: '💊',
    nameTh: 'สุขภาพ',
    nameEn: 'Health',
    isExpense: true,
    isDefault: true,
  ),
  TxCategory(
    id: 'exp_other',
    icon: '📌',
    nameTh: 'อื่นๆ',
    nameEn: 'Other',
    isExpense: true,
    isDefault: true,
  ),
  TxCategory(
    id: 'inc_salary',
    icon: '💰',
    nameTh: 'เงินเดือน',
    nameEn: 'Salary',
    isExpense: false,
    isDefault: true,
  ),
  TxCategory(
    id: 'inc_bonus',
    icon: '🎁',
    nameTh: 'โบนัส',
    nameEn: 'Bonus',
    isExpense: false,
    isDefault: true,
  ),
  TxCategory(
    id: 'inc_invest',
    icon: '📈',
    nameTh: 'การลงทุน',
    nameEn: 'Investments',
    isExpense: false,
    isDefault: true,
  ),
  TxCategory(
    id: 'inc_other',
    icon: '📌',
    nameTh: 'อื่นๆ',
    nameEn: 'Other',
    isExpense: false,
    isDefault: true,
  ),
];

class FinanceData extends ChangeNotifier {
  FinanceData({PetData? pet, FinanceStore? store})
    : _pet = pet ?? PetData.instance,
      _store = store ?? GuestFinanceStore();
  final FinanceStore _store;
  final PetData _pet;
  static const storageKey = 'finance_state_v1';
  Future<void> _writes = Future.value();
  Object? saveError;
  bool _disposed = false;
  int _pendingWrites = 0;
  bool get isSaving => _pendingWrites > 0;

  Future<void> load() async {
    final raw = await _store.read();
    if (_disposed) return;
    if (raw != null) {
      // Parse the entire snapshot first. Never overwrite unreadable data.
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['version'] != 1) {
        throw const FormatException('Unsupported finance data version');
      }
      final loadedAccounts = (m['accounts'] as List)
          .map((e) => Account.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final loadedTransactions = (m['transactions'] as List)
          .map((e) => Transaction.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final loadedCategories = (m['categories'] as List)
          .map((e) => TxCategory.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (loadedAccounts.any((a) => !a.balance.isFinite) ||
          loadedTransactions.any(
            (t) =>
                !t.amount.isFinite ||
                t.amount <= 0 ||
                !loadedAccounts.any((a) => a.id == t.accountId),
          )) {
        throw const FormatException('Invalid financial data');
      }
      accounts
        ..clear()
        ..addAll(loadedAccounts);
      transactions
        ..clear()
        ..addAll(loadedTransactions);
      categories
        ..clear()
        ..addAll(loadedCategories);
      for (final category in _defaultCategories) {
        if (!categories.any((c) => c.id == category.id)) {
          categories.add(category);
        }
      }
    }
    await _pet.load();
    if (_disposed) return;
    await _pet.syncIncomeRewards(_incomeRewards);
    if (!_disposed) notifyListeners();
  }

  // Calculate from cents so splitting income cannot create extra rewards.
  int get _incomeRewards =>
      transactions
          .where((t) => !t.isExpense)
          .fold<int>(0, (sum, t) => sum + (t.amount * 100).round()) ~/
      10000;

  void _changed() {
    if (_disposed) return;
    _pendingWrites++;
    final snapshot = jsonEncode({
      'version': 1,
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
    });
    final rewards = _incomeRewards;
    _writes = _writes.then((_) async {
      try {
        if (_disposed) return;
        await _store.write(snapshot);
        // Reconcile only after finance is saved. Startup retries if interrupted.
        if (!_disposed) await _pet.syncIncomeRewards(rewards);
        saveError = null;
      } catch (error) {
        saveError = error;
      }
      _pendingWrites--;
      if (!_disposed) notifyListeners();
    });
    notifyListeners();
  }

  Future<void> flush() async {
    await _writes;
    if (saveError != null) {
      throw StateError('Financial data could not be saved: $saveError');
    }
  }

  Future<void> reloadFromCloud() async {
    await _writes;
    await load();
    saveError = null;
    notifyListeners();
  }

  Future<void> retrySave() {
    _changed();
    return flush();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  TxCategory? categoryFor(Transaction t) {
    for (final c in categories) {
      if (t.categoryId != null
          ? c.id == t.categoryId
          : c.nameTh == t.category && c.isExpense == t.isExpense) {
        return c;
      }
    }
    return null;
  }

  final List<Account> accounts = [];
  final List<Transaction> transactions = [];
  final List<TxCategory> categories = List.from(_defaultCategories);

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  void setMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  // ── Filtered by selected month/year ───────────────────────────────────────

  List<Transaction> get filteredTransactions => transactions
      .where(
        (t) => t.date.month == _selectedMonth && t.date.year == _selectedYear,
      )
      .toList();

  // ── All-time balance (accounts screen total) ──────────────────────────────

  double get totalBalance => accounts.fold(0, (sum, a) => sum + a.balance);

  // ── Monthly aggregates ────────────────────────────────────────────────────

  double get monthlyIncome => filteredTransactions
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get monthlyExpense => filteredTransactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  // ── Transactions ──────────────────────────────────────────────────────────

  void addTransaction(Transaction t, {int index = 0}) {
    if (transactions.any((existing) => existing.id == t.id)) return;
    if (!t.amount.isFinite ||
        t.amount <= 0 ||
        !accounts.any((a) => a.id == t.accountId)) {
      throw ArgumentError(
        'A transaction needs a positive finite amount and an existing account',
      );
    }
    transactions.insert(index.clamp(0, transactions.length), t);
    final idx = accounts.indexWhere((a) => a.id == t.accountId);
    if (idx != -1) {
      final old = accounts[idx];
      accounts[idx] = Account(
        id: old.id,
        icon: old.icon,
        name: old.name,
        balance: old.balance + (t.isExpense ? -t.amount : t.amount),
      );
    }
    _changed();
  }

  void updateTransaction(Transaction replacement) {
    final index = transactions.indexWhere((t) => t.id == replacement.id);
    if (index < 0) throw ArgumentError('Transaction does not exist');
    if (!replacement.amount.isFinite ||
        replacement.amount <= 0 ||
        !accounts.any((a) => a.id == replacement.accountId)) {
      throw ArgumentError('Invalid transaction');
    }
    final old = transactions[index];
    for (var i = 0; i < accounts.length; i++) {
      final account = accounts[i];
      var balance = account.balance;
      if (account.id == old.accountId) {
        balance += old.isExpense ? old.amount : -old.amount;
      }
      if (account.id == replacement.accountId) {
        balance += replacement.isExpense
            ? -replacement.amount
            : replacement.amount;
      }
      accounts[i] = Account(
        id: account.id,
        icon: account.icon,
        name: account.name,
        balance: balance,
      );
    }
    transactions[index] = replacement;
    _changed();
  }

  void removeTransaction(String id) {
    final idx = transactions.indexWhere((tx) => tx.id == id);
    if (idx == -1) return;
    final t = transactions[idx];
    transactions.removeAt(idx);
    final aIdx = accounts.indexWhere((a) => a.id == t.accountId);
    if (aIdx != -1) {
      final old = accounts[aIdx];
      accounts[aIdx] = Account(
        id: old.id,
        icon: old.icon,
        name: old.name,
        balance: old.balance + (t.isExpense ? t.amount : -t.amount),
      );
    }
    _changed();
  }

  // ── Accounts ──────────────────────────────────────────────────────────────

  void addAccount(String name, {String icon = '🏦'}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    accounts.add(Account(id: id, icon: icon, name: name.trim(), balance: 0));
    _changed();
  }

  void renameAccount(String id, String newName, {String? newIcon}) {
    final index = accounts.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final old = accounts[index];
    accounts[index] = Account(
      id: old.id,
      icon: newIcon ?? old.icon,
      name: newName.trim(),
      balance: old.balance,
    );
    _changed();
  }

  void setAccountBalance(String id, double newBalance) {
    if (!newBalance.isFinite) throw ArgumentError.value(newBalance);
    final index = accounts.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final old = accounts[index];
    accounts[index] = Account(
      id: old.id,
      icon: old.icon,
      name: old.name,
      balance: newBalance,
    );
    _changed();
  }

  // ── Categories ────────────────────────────────────────────────────────────

  void addCategory(TxCategory c) {
    categories.add(c);
    _changed();
  }

  void updateCategory(
    String id, {
    String? icon,
    String? nameTh,
    String? nameEn,
  }) {
    final index = categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    categories[index] = categories[index].copyWith(
      icon: icon,
      nameTh: nameTh,
      nameEn: nameEn,
    );
    _changed();
  }

  void deleteCategory(String id) {
    categories.removeWhere((c) => c.id == id && !c.isDefault);
    _changed();
  }

  // ── Seed ──────────────────────────────────────────────────────────────────

  void seedDefaultAccount() {
    if (accounts.isEmpty) {
      addAccount('เงินออม', icon: '🏦');
    }
  }
}
