class CreditTermModel {
  final String id;
  final String companyId;
  final String name; // e.g., Net 30, Due on Receipt
  final int days;
  final bool isDefault;

  CreditTermModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.days,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'days': days,
      'isDefault': isDefault,
    };
  }

  factory CreditTermModel.fromMap(Map<String, dynamic> map, String id) {
    return CreditTermModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      days: map['days'] ?? 0,
      isDefault: map['isDefault'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditTermModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
