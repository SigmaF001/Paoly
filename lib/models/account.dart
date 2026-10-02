class Account {
  final String id;
  final String icon;
  final String name;
  final double balance;

  Account({
    required this.id,
    required this.icon,
    required this.name,
    required this.balance,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'name': name,
    'balance': balance,
  };
  factory Account.fromJson(Map<String, dynamic> m) => Account(
    id: m['id'] as String,
    icon: m['icon'] as String,
    name: m['name'] as String,
    balance: (m['balance'] as num).toDouble(),
  );
}
