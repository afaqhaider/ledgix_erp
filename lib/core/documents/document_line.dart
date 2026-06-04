class DocumentLine {
  final String id;
  final String itemId;
  final String itemName;
  final String description;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;
  final double taxAmount;
  final double discountAmount;
  final double netAmount;

  const DocumentLine({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.description = '',
    required this.quantity,
    this.unit = 'Unit',
    required this.rate,
    required this.amount,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.netAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'amount': amount,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'netAmount': netAmount,
    };
  }

  factory DocumentLine.fromMap(Map<String, dynamic> map) {
    return DocumentLine(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'Unit',
      rate: (map['rate'] ?? 0.0).toDouble(),
      amount: (map['amount'] ?? 0.0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0.0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      netAmount: (map['netAmount'] ?? 0.0).toDouble(),
    );
  }
}
