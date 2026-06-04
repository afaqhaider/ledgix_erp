import 'package:cloud_firestore/cloud_firestore.dart';

class StockItemModel {
  final String itemId;
  final String itemCode;
  final String itemName;
  final double quantity;
  final String uomId;
  final double? unitCost;

  StockItemModel({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.uomId,
    this.unitCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemCode': itemCode,
      'itemName': itemName,
      'quantity': quantity,
      'uomId': uomId,
      'unitCost': unitCost,
    };
  }

  factory StockItemModel.fromMap(Map<String, dynamic> map) {
    return StockItemModel(
      itemId: map['itemId'] ?? '',
      itemCode: map['itemCode'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      uomId: map['uomId'] ?? '',
      unitCost: (map['unitCost'] as num?)?.toDouble(),
    );
  }
}

class GrnModel {
  final String id;
  final String companyId;
  final String grnNumber;
  final String supplierId;
  final String? poReference;
  final String warehouseId;
  final DateTime date;
  final List<StockItemModel> items;
  final String? notes;
  final String createdBy;

  GrnModel({
    required this.id,
    required this.companyId,
    required this.grnNumber,
    required this.supplierId,
    this.poReference,
    required this.warehouseId,
    required this.date,
    required this.items,
    this.notes,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'grnNumber': grnNumber,
      'supplierId': supplierId,
      'poReference': poReference,
      'warehouseId': warehouseId,
      'date': Timestamp.fromDate(date),
      'items': items.map((i) => i.toMap()).toList(),
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  factory GrnModel.fromMap(Map<String, dynamic> map, String id) {
    return GrnModel(
      id: id,
      companyId: map['companyId'] ?? '',
      grnNumber: map['grnNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      poReference: map['poReference'],
      warehouseId: map['warehouseId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (map['items'] as List? ?? []).map((i) => StockItemModel.fromMap(i)).toList(),
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
    );
  }
}

class DeliveryNoteModel {
  final String id;
  final String companyId;
  final String dnNumber;
  final String customerId;
  final String warehouseId;
  final DateTime date;
  final List<StockItemModel> items;
  final String? notes;
  final String createdBy;

  DeliveryNoteModel({
    required this.id,
    required this.companyId,
    required this.dnNumber,
    required this.customerId,
    required this.warehouseId,
    required this.date,
    required this.items,
    this.notes,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'dnNumber': dnNumber,
      'customerId': customerId,
      'warehouseId': warehouseId,
      'date': Timestamp.fromDate(date),
      'items': items.map((i) => i.toMap()).toList(),
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  factory DeliveryNoteModel.fromMap(Map<String, dynamic> map, String id) {
    return DeliveryNoteModel(
      id: id,
      companyId: map['companyId'] ?? '',
      dnNumber: map['dnNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      warehouseId: map['warehouseId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (map['items'] as List? ?? []).map((i) => StockItemModel.fromMap(i)).toList(),
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
    );
  }
}

class InventoryTransferModel {
  final String id;
  final String companyId;
  final String transferNumber;
  final String sourceWarehouseId;
  final String destinationWarehouseId;
  final DateTime date;
  final List<StockItemModel> items;
  final String? notes;
  final String createdBy;

  InventoryTransferModel({
    required this.id,
    required this.companyId,
    required this.transferNumber,
    required this.sourceWarehouseId,
    required this.destinationWarehouseId,
    required this.date,
    required this.items,
    this.notes,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'transferNumber': transferNumber,
      'sourceWarehouseId': sourceWarehouseId,
      'destinationWarehouseId': destinationWarehouseId,
      'date': Timestamp.fromDate(date),
      'items': items.map((i) => i.toMap()).toList(),
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  factory InventoryTransferModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryTransferModel(
      id: id,
      companyId: map['companyId'] ?? '',
      transferNumber: map['transferNumber'] ?? '',
      sourceWarehouseId: map['sourceWarehouseId'] ?? '',
      destinationWarehouseId: map['destinationWarehouseId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (map['items'] as List? ?? []).map((i) => StockItemModel.fromMap(i)).toList(),
      notes: map['notes'],
      createdBy: map['createdBy'] ?? '',
    );
  }
}

class PhysicalVerificationModel {
  final String id;
  final String companyId;
  final String countNumber;
  final String warehouseId;
  final DateTime date;
  final List<VerificationItemModel> items;
  final String? status; // draft, approved
  final String createdBy;

  PhysicalVerificationModel({
    required this.id,
    required this.companyId,
    required this.countNumber,
    required this.warehouseId,
    required this.date,
    required this.items,
    this.status = 'draft',
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'countNumber': countNumber,
      'warehouseId': warehouseId,
      'date': Timestamp.fromDate(date),
      'items': items.map((i) => i.toMap()).toList(),
      'status': status,
      'createdBy': createdBy,
    };
  }

  factory PhysicalVerificationModel.fromMap(Map<String, dynamic> map, String id) {
    return PhysicalVerificationModel(
      id: id,
      companyId: map['companyId'] ?? '',
      countNumber: map['countNumber'] ?? '',
      warehouseId: map['warehouseId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (map['items'] as List? ?? []).map((i) => VerificationItemModel.fromMap(i)).toList(),
      status: map['status'] ?? 'draft',
      createdBy: map['createdBy'] ?? '',
    );
  }
}

class VerificationItemModel {
  final String itemId;
  final String itemCode;
  final String itemName;
  final double systemQuantity;
  final double physicalQuantity;
  final double variance;

  VerificationItemModel({
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.systemQuantity,
    required this.physicalQuantity,
    required this.variance,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemCode': itemCode,
      'itemName': itemName,
      'systemQuantity': systemQuantity,
      'physicalQuantity': physicalQuantity,
      'variance': variance,
    };
  }

  factory VerificationItemModel.fromMap(Map<String, dynamic> map) {
    return VerificationItemModel(
      itemId: map['itemId'] ?? '',
      itemCode: map['itemCode'] ?? '',
      itemName: map['itemName'] ?? '',
      systemQuantity: (map['systemQuantity'] as num?)?.toDouble() ?? 0.0,
      physicalQuantity: (map['physicalQuantity'] as num?)?.toDouble() ?? 0.0,
      variance: (map['variance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StockLedgerModel {
  final String id;
  final String companyId;
  final String itemId;
  final String warehouseId;
  final DateTime date;
  final String referenceType; // GRN, DN, Transfer, Adjustment, Opening
  final String referenceNumber;
  final double quantityIn;
  final double quantityOut;
  final double balanceAfter;

  StockLedgerModel({
    required this.id,
    required this.companyId,
    required this.itemId,
    required this.warehouseId,
    required this.date,
    required this.referenceType,
    required this.referenceNumber,
    this.quantityIn = 0.0,
    this.quantityOut = 0.0,
    required this.balanceAfter,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'itemId': itemId,
      'warehouseId': warehouseId,
      'date': Timestamp.fromDate(date),
      'referenceType': referenceType,
      'referenceNumber': referenceNumber,
      'quantityIn': quantityIn,
      'quantityOut': quantityOut,
      'balanceAfter': balanceAfter,
    };
  }

  factory StockLedgerModel.fromMap(Map<String, dynamic> map, String id) {
    return StockLedgerModel(
      id: id,
      companyId: map['companyId'] ?? '',
      itemId: map['itemId'] ?? '',
      warehouseId: map['warehouseId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      referenceType: map['referenceType'] ?? '',
      referenceNumber: map['referenceNumber'] ?? '',
      quantityIn: (map['quantityIn'] as num?)?.toDouble() ?? 0.0,
      quantityOut: (map['quantityOut'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (map['balanceAfter'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
