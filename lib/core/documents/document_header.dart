import 'package:ledgixerp/core/documents/document_status.dart';
import 'package:ledgixerp/core/documents/document_line.dart';

enum DocumentType {
  quotation,
  salesInvoice,
  purchaseOrder,
  receiptVoucher,
  paymentVoucher,
  creditNote,
  debitNote;

  String get label {
    switch (this) {
      case DocumentType.quotation:
        return 'Quotation';
      case DocumentType.salesInvoice:
        return 'Sales Invoice';
      case DocumentType.purchaseOrder:
        return 'Purchase Order';
      case DocumentType.receiptVoucher:
        return 'Receipt Voucher';
      case DocumentType.paymentVoucher:
        return 'Payment Voucher';
      case DocumentType.creditNote:
        return 'Credit Note';
      case DocumentType.debitNote:
        return 'Debit Note';
    }
  }
}

class DocumentHeader {
  final String documentId;
  final String documentNumber;
  final DateTime documentDate;
  final String companyId;
  final String entityId; // customerId or supplierId
  final String entityName;
  final String currency;
  final DocumentStatus status;
  final DocumentType type;
  final String notes;
  final String createdBy;
  final DateTime createdAt;
  final List<DocumentLine> lines;

  // Totals
  final double subtotal;
  final double taxTotal;
  final double discountTotal;
  final double totalAmount;

  const DocumentHeader({
    required this.documentId,
    required this.documentNumber,
    required this.documentDate,
    required this.companyId,
    required this.entityId,
    required this.entityName,
    this.currency = 'AED',
    this.status = DocumentStatus.draft,
    required this.type,
    this.notes = '',
    required this.createdBy,
    required this.createdAt,
    this.lines = const [],
    this.subtotal = 0.0,
    this.taxTotal = 0.0,
    this.discountTotal = 0.0,
    this.totalAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'documentNumber': documentNumber,
      'documentDate': documentDate.toIso8601String(),
      'companyId': companyId,
      'entityId': entityId,
      'entityName': entityName,
      'currency': currency,
      'status': status.name,
      'type': type.name,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'subtotal': subtotal,
      'taxTotal': taxTotal,
      'discountTotal': discountTotal,
      'totalAmount': totalAmount,
    };
  }

  factory DocumentHeader.fromMap(
    Map<String, dynamic> map, {
    List<DocumentLine> lines = const [],
  }) {
    return DocumentHeader(
      documentId: map['documentId'] ?? '',
      documentNumber: map['documentNumber'] ?? '',
      documentDate: DateTime.parse(
        map['documentDate'] ?? DateTime.now().toIso8601String(),
      ),
      companyId: map['companyId'] ?? '',
      entityId: map['entityId'] ?? '',
      entityName: map['entityName'] ?? '',
      currency: map['currency'] ?? 'AED',
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DocumentStatus.draft,
      ),
      type: DocumentType.values.firstWhere((e) => e.name == map['type']),
      notes: map['notes'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lines: lines,
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      taxTotal: (map['taxTotal'] ?? 0.0).toDouble(),
      discountTotal: (map['discountTotal'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
    );
  }
}
