import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductType { service, storable, consumable }

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
  final double costPrice;
  final double stockQuantity;
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
      incomeAccountId: map['incomeAccountId'],
      expenseAccountId: map['expenseAccountId'],
      assetAccountId: map['assetAccountId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
