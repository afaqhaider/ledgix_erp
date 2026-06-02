import 'package:cloud_firestore/cloud_firestore.dart';

enum QuotationStatus { draft, sent, accepted, rejected, expired, converted }

class QuotationLineItemModel {
  final String description;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double lineSubtotal;
  final double lineVat;
  final double lineTotal;

  QuotationLineItemModel({
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
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
      'lineSubtotal': lineSubtotal,
      'lineVat': lineVat,
      'lineTotal': lineTotal,
    };
  }

  factory QuotationLineItemModel.fromMap(Map<String, dynamic> map) {
    return QuotationLineItemModel(
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

class QuotationModel {
  final String id;
  final String companyId;
  final String quotationNumber;
  final String customerId;
  final String customerName;
  final DateTime quotationDate;
  final DateTime validUntilDate;
  final QuotationStatus status;
  final List<QuotationLineItemModel> items;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final String? notes;
  final String? termsAndConditions;
  final DateTime createdAt;
  final String? approvalStatus;

  QuotationModel({
    required this.id,
    required this.companyId,
    required this.quotationNumber,
    required this.customerId,
    required this.customerName,
    required this.quotationDate,
    required this.validUntilDate,
    this.status = QuotationStatus.draft,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    this.notes,
    this.termsAndConditions,
    required this.createdAt,
    this.approvalStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'quotationNumber': quotationNumber,
      'customerId': customerId,
      'customerName': customerName,
      'quotationDate': quotationDate,
      'validUntilDate': validUntilDate,
      'status': status.name,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'notes': notes,
      'termsAndConditions': termsAndConditions,
      'createdAt': createdAt,
      'approvalStatus': approvalStatus,
    };
  }

  factory QuotationModel.fromMap(Map<String, dynamic> map, String id) {
    return QuotationModel(
      id: id,
      companyId: map['companyId'] ?? '',
      quotationNumber: map['quotationNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      quotationDate: (map['quotationDate'] as Timestamp).toDate(),
      validUntilDate: (map['validUntilDate'] as Timestamp).toDate(),
      status: QuotationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QuotationStatus.draft,
      ),
      items:
          (map['items'] as List<dynamic>?)
              ?.map(
                (i) =>
                    QuotationLineItemModel.fromMap(i as Map<String, dynamic>),
              )
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (map['vatAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      termsAndConditions: map['termsAndConditions'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      approvalStatus: map['approvalStatus'],
    );
  }
}
