class Transaction {
  final String id;
  final String icon;
  final String title;
  final String category;
  final String? categoryId;
  final DateTime date;
  final double amount;
  final bool isExpense;
  final String accountId;

  Transaction({
    required this.id,
    required this.icon,
    required this.title,
    required this.category,
    this.categoryId,
    required this.date,
    required this.amount,
    required this.isExpense,
    required this.accountId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'title': title,
    'category': category,
    'categoryId': categoryId,
    'date': date.toIso8601String(),
    'amount': amount,
    'isExpense': isExpense,
    'accountId': accountId,
  };
  factory Transaction.fromJson(Map<String, dynamic> m) => Transaction(
    id: m['id'] as String,
    icon: m['icon'] as String,
    title: m['title'] as String,
    category: m['category'] as String,
    categoryId: m['categoryId'] as String?,
    date: DateTime.parse(m['date'] as String),
    amount: (m['amount'] as num).toDouble(),
    isExpense: m['isExpense'] as bool,
    accountId: m['accountId'] as String,
  );
}
