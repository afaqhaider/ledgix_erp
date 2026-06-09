import 'package:cloud_firestore/cloud_firestore.dart';

// Inventory Model Foundation

enum InventoryItemType { stock, service, nonStock }

extension InventoryItemTypeExtension on InventoryItemType {
  String get label {
    switch (this) {
      case InventoryItemType.stock:
        return 'Stock Item';
      case InventoryItemType.service:
        return 'Service Item';
      case InventoryItemType.nonStock:
        return 'Non-Stock Item';
    }
  }
}

class InventoryItemModel {
  final String id;
  final String companyId;
  final String itemCode;
  final String itemName;
  final String? itemDescription;
  final String? itemCategoryId;
  final InventoryItemType itemType;
  final String defaultUomId;
  final double salesPrice;
  final double purchasePrice;
  final String? inventoryAccountId;
  final String? incomeAccountId;
  final String? expenseAccountId;
  final double reorderLevel;
  final double minimumStock;
  final double maximumStock;
  final double stockQuantity; // Denormalized stock balance
  final double costPrice; // Weighted Average Cost
  final bool isActive;
  final DateTime createdAt;

  InventoryItemModel({
    required this.id,
    required this.companyId,
    required this.itemCode,
    required this.itemName,
    this.itemDescription,
    this.itemCategoryId,
    required this.itemType,
    required this.defaultUomId,
    this.salesPrice = 0.0,
    this.purchasePrice = 0.0,
    this.inventoryAccountId,
    this.incomeAccountId,
    this.expenseAccountId,
    this.reorderLevel = 0.0,
    this.minimumStock = 0.0,
    this.maximumStock = 0.0,
    this.stockQuantity = 0.0,
    this.costPrice = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'itemCode': itemCode,
      'itemName': itemName,
      'itemDescription': itemDescription,
      'itemCategoryId': itemCategoryId,
      'itemType': itemType.name,
      'defaultUomId': defaultUomId,
      'salesPrice': salesPrice,
      'purchasePrice': purchasePrice,
      'inventoryAccountId': inventoryAccountId,
      'incomeAccountId': incomeAccountId,
      'expenseAccountId': expenseAccountId,
      'reorderLevel': reorderLevel,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'stockQuantity': stockQuantity,
      'costPrice': costPrice,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory InventoryItemModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryItemModel(
      id: id,
      companyId: map['companyId'] ?? '',
      itemCode: map['itemCode'] ?? '',
      itemName: map['itemName'] ?? '',
      itemDescription: map['itemDescription'],
      itemCategoryId: map['itemCategoryId'],
      itemType: InventoryItemType.values.firstWhere(
        (e) => e.name == map['itemType'],
        orElse: () => InventoryItemType.stock,
      ),
      defaultUomId: map['defaultUomId'] ?? '',
      salesPrice: (map['salesPrice'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      inventoryAccountId: map['inventoryAccountId'],
      incomeAccountId: map['incomeAccountId'],
      expenseAccountId: map['expenseAccountId'],
      reorderLevel: (map['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      minimumStock: (map['minimumStock'] as num?)?.toDouble() ?? 0.0,
      maximumStock: (map['maximumStock'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class InventoryCategoryModel {
  final String id;
  final String companyId;
  final String name;
  final String? parentCategoryId;
  final bool isActive;

  InventoryCategoryModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.parentCategoryId,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'parentCategoryId': parentCategoryId,
      'isActive': isActive,
    };
  }

  factory InventoryCategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryCategoryModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      parentCategoryId: map['parentCategoryId'],
      isActive: map['isActive'] ?? true,
    );
  }
}

class WarehouseModel {
  final String id;
  final String companyId;
  final String warehouseCode;
  final String warehouseName;
  final String? address;
  final String? contactPerson;
  final String? contactNumber;
  final bool isActive;

  WarehouseModel({
    required this.id,
    required this.companyId,
    required this.warehouseCode,
    required this.warehouseName,
    this.address,
    this.contactPerson,
    this.contactNumber,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'warehouseCode': warehouseCode,
      'warehouseName': warehouseName,
      'address': address,
      'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      'isActive': isActive,
    };
  }

  factory WarehouseModel.fromMap(Map<String, dynamic> map, String id) {
    return WarehouseModel(
      id: id,
      companyId: map['companyId'] ?? '',
      warehouseCode: map['warehouseCode'] ?? '',
      warehouseName: map['warehouseName'] ?? '',
      address: map['address'],
      contactPerson: map['contactPerson'],
      contactNumber: map['contactNumber'],
      isActive: map['isActive'] ?? true,
    );
  }
}

class UomModel {
  final String id;
  final String companyId;
  final String uomName;
  final String uomCode;
  final int decimalPrecision;

  UomModel({
    required this.id,
    required this.companyId,
    required this.uomName,
    required this.uomCode,
    this.decimalPrecision = 2,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'uomName': uomName,
      'uomCode': uomCode,
      'decimalPrecision': decimalPrecision,
    };
  }

  factory UomModel.fromMap(Map<String, dynamic> map, String id) {
    return UomModel(
      id: id,
      companyId: map['companyId'] ?? '',
      uomName: map['uomName'] ?? map['name'] ?? '',
      uomCode: map['uomCode'] ?? map['symbol'] ?? '',
      decimalPrecision: map['decimalPrecision'] ?? map['precision'] ?? 2,
    );
  }
}

class UomConversionModel {
  final String id;
  final String companyId;
  final String? itemId;
  final String fromUomId;
  final String toUomId;
  final double conversionFactor;

  UomConversionModel({
    required this.id,
    required this.companyId,
    this.itemId,
    required this.fromUomId,
    required this.toUomId,
    required this.conversionFactor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'itemId': itemId,
      'fromUomId': fromUomId,
      'toUomId': toUomId,
      'conversionFactor': conversionFactor,
    };
  }

  factory UomConversionModel.fromMap(Map<String, dynamic> map, String id) {
    return UomConversionModel(
      id: id,
      companyId: map['companyId'] ?? '',
      itemId: map['itemId'],
      fromUomId: map['fromUomId'] ?? '',
      toUomId: map['toUomId'] ?? '',
      conversionFactor: (map['conversionFactor'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
