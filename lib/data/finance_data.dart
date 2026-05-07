import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';

const List<TxCategory> _defaultCategories = [
  TxCategory(id: 'exp_food',      icon: '🍔', nameTh: 'อาหาร',     nameEn: 'Food',          isExpense: true,  isDefault: true),
  TxCategory(id: 'exp_travel',    icon: '🚗', nameTh: 'เดินทาง',   nameEn: 'Transport',     isExpense: true,  isDefault: true),
  TxCategory(id: 'exp_shopping',  icon: '🛍️', nameTh: 'ช้อปปิ้ง',  nameEn: 'Shopping',      isExpense: true,  isDefault: true),
  TxCategory(id: 'exp_entertain', icon: '🎮', nameTh: 'บันเทิง',   nameEn: 'Entertainment', isExpense: true,  isDefault: true),
  TxCategory(id: 'exp_util',      icon: '💡', nameTh: 'ค่าไฟ/น้ำ', nameEn: 'Utilities',     isExpense: true,  isDefault: true),
  TxCategory(id: 'exp_health',    icon: '💊', nameTh: 'สุขภาพ',    nameEn: 'Health',        isExpense: true,  isDefault: true),
  TxCategory(id: 'exp_other',     icon: '📌', nameTh: 'อื่นๆ',     nameEn: 'Other',         isExpense: true,  isDefault: true),
  TxCategory(id: 'inc_salary',    icon: '💰', nameTh: 'เงินเดือน', nameEn: 'Salary',        isExpense: false, isDefault: true),
  TxCategory(id: 'inc_bonus',     icon: '🎁', nameTh: 'โบนัส',     nameEn: 'Bonus',         isExpense: false, isDefault: true),
  TxCategory(id: 'inc_invest',    icon: '📈', nameTh: 'การลงทุน',  nameEn: 'Investments',   isExpense: false, isDefault: true),
  TxCategory(id: 'inc_other',     icon: '📌', nameTh: 'อื่นๆ',     nameEn: 'Other',         isExpense: false, isDefault: true),
];

class FinanceData extends ChangeNotifier {
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
      .where((t) => t.date.month == _selectedMonth && t.date.year == _selectedYear)
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

  void addTransaction(Transaction t) {
    transactions.insert(0, t);
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
    notifyListeners();
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
    notifyListeners();
  }

  // ── Accounts ──────────────────────────────────────────────────────────────

  void addAccount(String name, {String icon = '🏦'}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    accounts.add(Account(id: id, icon: icon, name: name.trim(), balance: 0));
    notifyListeners();
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
    notifyListeners();
  }

  void setAccountBalance(String id, double newBalance) {
    final index = accounts.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final old = accounts[index];
    accounts[index] = Account(
      id: old.id,
      icon: old.icon,
      name: old.name,
      balance: newBalance,
    );
    notifyListeners();
  }

  // ── Categories ────────────────────────────────────────────────────────────

  void addCategory(TxCategory c) {
    categories.add(c);
    notifyListeners();
  }

  void updateCategory(String id, {String? icon, String? nameTh, String? nameEn}) {
    final index = categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    categories[index] = categories[index].copyWith(
      icon: icon,
      nameTh: nameTh,
      nameEn: nameEn,
    );
    notifyListeners();
  }

  void deleteCategory(String id) {
    categories.removeWhere((c) => c.id == id && !c.isDefault);
    notifyListeners();
  }

  // ── Seed ──────────────────────────────────────────────────────────────────

  void seedDefaultAccount() {
    if (accounts.isEmpty) {
      addAccount('เงินออม', icon: '🏦');
    }
  }
}
