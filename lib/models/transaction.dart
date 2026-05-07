class Transaction {
  final String id;
  final String icon;
  final String title;
  final String category;
  final DateTime date;
  final double amount;
  final bool isExpense;
  final String accountId;

  Transaction({
    required this.id,
    required this.icon,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.isExpense,
    required this.accountId,
  });
}
