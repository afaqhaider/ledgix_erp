class PaymentTermModel {
  final String id;
  final String companyId;
  final String name;
  final int days;
  final bool isDefault;

  PaymentTermModel({
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

  factory PaymentTermModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentTermModel(
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
      other is PaymentTermModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
