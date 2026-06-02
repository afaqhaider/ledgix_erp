import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus { draft, sent, partiallyPaid, paid, cancelled }

class InvoiceLineItemModel {
  final String description;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double lineSubtotal;
  final double lineVat;
  final double lineTotal;

  InvoiceLineItemModel({
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

  factory InvoiceLineItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItemModel(
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

class InvoiceModel {
  final String id;
  final String companyId;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final List<InvoiceLineItemModel> items;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final DateTime createdAt;

  // Customization fields
  final String? invoiceTemplateId;
  final String? primaryBrandColor;
  final String? secondaryBrandColor;
  final String? companyLogoUrl;

  // Posting fields
  final bool isPosted;
  final String? journalEntryId;
  final String? approvalStatus; // pending, approved, rejected

  InvoiceModel({
    required this.id,
    required this.companyId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.invoiceDate,
    required this.dueDate,
    this.status = InvoiceStatus.draft,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    this.amountPaid = 0.0,
    required this.balanceDue,
    required this.createdAt,
    this.invoiceTemplateId,
    this.primaryBrandColor,
    this.secondaryBrandColor,
    this.companyLogoUrl,
    this.isPosted = false,
    this.journalEntryId,
    this.approvalStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'invoiceDate': invoiceDate,
      'dueDate': dueDate,
      'status': status.name,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'balanceDue': balanceDue,
      'createdAt': createdAt,
      'invoiceTemplateId': invoiceTemplateId,
      'primaryBrandColor': primaryBrandColor,
      'secondaryBrandColor': secondaryBrandColor,
      'companyLogoUrl': companyLogoUrl,
      'isPosted': isPosted,
      'journalEntryId': journalEntryId,
      'approvalStatus': approvalStatus,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      companyId: map['companyId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      invoiceDate: (map['invoiceDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      items: (map['items'] as List<dynamic>?)
              ?.map((i) => InvoiceLineItemModel.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (map['vatAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balanceDue'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      invoiceTemplateId: map['invoiceTemplateId'],
      primaryBrandColor: map['primaryBrandColor'],
      secondaryBrandColor: map['secondaryBrandColor'],
      companyLogoUrl: map['companyLogoUrl'],
      isPosted: map['isPosted'] ?? false,
      journalEntryId: map['journalEntryId'],
      approvalStatus: map['approvalStatus'],
    );
  }
}
