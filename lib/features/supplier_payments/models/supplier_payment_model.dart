import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, bank, card, cheque, online }

class SupplierPaymentModel {
  final String id;
  final String companyId;
  final String paymentNumber;
  final String supplierId;
  final String supplierName;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final String? bankAccountId; // Linked to Banking module
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? referenceNumber;
  final double amount;
  final String? notes;
  final DateTime createdAt;

  // Posting fields
  final bool isPosted;
  final String? journalEntryId;
  final String? approvalStatus;

  SupplierPaymentModel({
    required this.id,
    required this.companyId,
    required this.paymentNumber,
    required this.supplierId,
    required this.supplierName,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    this.bankAccountId,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNumber,
    required this.amount,
    this.notes,
    required this.createdAt,
    this.isPosted = false,
    this.journalEntryId,
    this.approvalStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'paymentNumber': paymentNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseOrderId': purchaseOrderId,
      'purchaseOrderNumber': purchaseOrderNumber,
      'bankAccountId': bankAccountId,
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod.name,
      'referenceNumber': referenceNumber,
      'amount': amount,
      'notes': notes,
      'createdAt': createdAt,
      'isPosted': isPosted,
      'journalEntryId': journalEntryId,
      'approvalStatus': approvalStatus,
    };
  }

  factory SupplierPaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return SupplierPaymentModel(
      id: id,
      companyId: map['companyId'] ?? '',
      paymentNumber: map['paymentNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      purchaseOrderId: map['purchaseOrderId'],
      purchaseOrderNumber: map['purchaseOrderNumber'],
      bankAccountId: map['bankAccountId'],
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.bank,
      ),
      referenceNumber: map['referenceNumber'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isPosted: map['isPosted'] ?? false,
      journalEntryId: map['journalEntryId'],
      approvalStatus: map['approvalStatus'],
    );
  }
}
