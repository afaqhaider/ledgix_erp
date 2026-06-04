import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/models/attachment_model.dart';

enum POStatus { draft, sent, partiallyReceived, received, cancelled }

class POLineItemModel {
  final String? productId;
  final String? accountId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double lineSubtotal;
  final double lineVat;
  final double lineTotal;

  POLineItemModel({
    this.productId,
    this.accountId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.lineSubtotal,
    required this.lineVat,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'accountId': accountId,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
      'lineSubtotal': lineSubtotal,
      'lineVat': lineVat,
      'lineTotal': lineTotal,
    };
  }

  factory POLineItemModel.fromMap(Map<String, dynamic> map) {
    return POLineItemModel(
      productId: map['productId'],
      accountId: map['accountId'],
      description: map['description'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      vatRate: (map['vatRate'] as num?)?.toDouble() ?? 0.0,
      lineSubtotal: (map['lineSubtotal'] as num?)?.toDouble() ?? 0.0,
      lineVat: (map['lineVat'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PurchaseOrderModel {
  final String id;
  final String companyId;
  final String poNumber;
  final String supplierId;
  final String supplierName;
  final DateTime poDate;
  final DateTime expectedDeliveryDate;
  final POStatus status;
  final List<POLineItemModel> items;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final String? approvalStatus;
  final bool isReceived;
  final List<AttachmentModel> attachments;

  PurchaseOrderModel({
    required this.id,
    required this.companyId,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    required this.poDate,
    required this.expectedDeliveryDate,
    this.status = POStatus.draft,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.approvalStatus,
    this.isReceived = false,
    this.attachments = const [],
  });

  PurchaseOrderModel copyWith({
    String? id,
    String? companyId,
    String? poNumber,
    String? supplierId,
    String? supplierName,
    DateTime? poDate,
    DateTime? expectedDeliveryDate,
    POStatus? status,
    List<POLineItemModel>? items,
    double? subtotal,
    double? vatAmount,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    String? approvalStatus,
    bool? isReceived,
    List<AttachmentModel>? attachments,
  }) {
    return PurchaseOrderModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      poNumber: poNumber ?? this.poNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      poDate: poDate ?? this.poDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isReceived: isReceived ?? this.isReceived,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'poNumber': poNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'poDate': Timestamp.fromDate(poDate),
      'expectedDeliveryDate': Timestamp.fromDate(expectedDeliveryDate),
      'status': status.name,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvalStatus': approvalStatus,
      'isReceived': isReceived,
      'attachments': attachments.map((x) => x.toMap()).toList(),
    };
  }

  factory PurchaseOrderModel.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseOrderModel(
      id: id,
      companyId: map['companyId'] ?? '',
      poNumber: map['poNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      poDate: (map['poDate'] as Timestamp).toDate(),
      expectedDeliveryDate: (map['expectedDeliveryDate'] as Timestamp).toDate(),
      status: POStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => POStatus.draft,
      ),
      items:
          (map['items'] as List<dynamic>?)
              ?.map((i) => POLineItemModel.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (map['vatAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      approvalStatus: map['approvalStatus'],
      isReceived: map['isReceived'] ?? false,
      attachments:
          (map['attachments'] as List?)
              ?.map((x) => AttachmentModel.fromMap(x))
              .toList() ??
          [],
    );
  }
}
