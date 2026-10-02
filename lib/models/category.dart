class TxCategory {
  final String id;
  final String icon;
  final String nameTh;
  final String nameEn;
  final bool isExpense;
  final bool isDefault;

  const TxCategory({
    required this.id,
    required this.icon,
    required this.nameTh,
    required this.nameEn,
    required this.isExpense,
    this.isDefault = false,
  });

  TxCategory copyWith({String? icon, String? nameTh, String? nameEn}) =>
      TxCategory(
        id: id,
        icon: icon ?? this.icon,
        nameTh: nameTh ?? this.nameTh,
        nameEn: nameEn ?? this.nameEn,
        isExpense: isExpense,
        isDefault: isDefault,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'nameTh': nameTh,
    'nameEn': nameEn,
    'isExpense': isExpense,
    'isDefault': isDefault,
  };
  factory TxCategory.fromJson(Map<String, dynamic> m) => TxCategory(
    id: m['id'] as String,
    icon: m['icon'] as String,
    nameTh: m['nameTh'] as String,
    nameEn: m['nameEn'] as String,
    isExpense: m['isExpense'] as bool,
    isDefault: m['isDefault'] as bool? ?? false,
  );
}
