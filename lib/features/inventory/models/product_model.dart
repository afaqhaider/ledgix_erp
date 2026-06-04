import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductType { service, storable, consumable }

class StockBatch {
  final String? purchaseId;
  final DateTime date;
  final double quantity;
  double remainingQuantity;
  final double unitCost;

  StockBatch({
    this.purchaseId,
    required this.date,
    required this.quantity,
    required this.remainingQuantity,
    required this.unitCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'purchaseId': purchaseId,
      'date': Timestamp.fromDate(date),
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'unitCost': unitCost,
    };
  }

  factory StockBatch.fromMap(Map<String, dynamic> map) {
    return StockBatch(
      purchaseId: map['purchaseId'],
      date: (map['date'] as Timestamp).toDate(),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      remainingQuantity: (map['remainingQuantity'] as num?)?.toDouble() ?? 0.0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProductModel {
  final String id;
  final String companyId;
  final String sku;
  final String name;
  final String? description;
  final ProductType type;
  final String? category;
  final String uom; // Unit of Measure
  final double salePrice;
  final double costPrice; // Current cost (for Weighted Average)
  final double stockQuantity;
  final List<StockBatch> stockBatches; // For FIFO
  final String? incomeAccountId;
  final String? expenseAccountId;
  final String? assetAccountId; // For inventory valuation
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.companyId,
    required this.sku,
    required this.name,
    this.description,
    this.type = ProductType.storable,
    this.category,
    this.uom = 'Units',
    this.salePrice = 0.0,
    this.costPrice = 0.0,
    this.stockQuantity = 0.0,
    this.stockBatches = const [],
    this.incomeAccountId,
    this.expenseAccountId,
    this.assetAccountId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'sku': sku,
      'name': name,
      'description': description,
      'type': type.name,
      'category': category,
      'uom': uom,
      'salePrice': salePrice,
      'costPrice': costPrice,
      'stockQuantity': stockQuantity,
      'stockBatches': stockBatches.map((b) => b.toMap()).toList(),
      'incomeAccountId': incomeAccountId,
      'expenseAccountId': expenseAccountId,
      'assetAccountId': assetAccountId,
      'createdAt': createdAt,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      companyId: map['companyId'] ?? '',
      sku: map['sku'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      type: ProductType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ProductType.storable,
      ),
      category: map['category'],
      uom: map['uom'] ?? 'Units',
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      stockBatches:
          (map['stockBatches'] as List<dynamic>?)
              ?.map((b) => StockBatch.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      incomeAccountId: map['incomeAccountId'],
      expenseAccountId: map['expenseAccountId'],
      assetAccountId: map['assetAccountId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  ProductModel copyWith({
    String? id,
    String? companyId,
    String? sku,
    String? name,
    String? description,
    ProductType? type,
    String? category,
    String? uom,
    double? salePrice,
    double? costPrice,
    double? stockQuantity,
    List<StockBatch>? stockBatches,
    String? incomeAccountId,
    String? expenseAccountId,
    String? assetAccountId,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      uom: uom ?? this.uom,
      salePrice: salePrice ?? this.salePrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockBatches: stockBatches ?? this.stockBatches,
      incomeAccountId: incomeAccountId ?? this.incomeAccountId,
      expenseAccountId: expenseAccountId ?? this.expenseAccountId,
      assetAccountId: assetAccountId ?? this.assetAccountId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
