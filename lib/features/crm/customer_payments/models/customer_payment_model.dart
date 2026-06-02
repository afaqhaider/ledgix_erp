import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerPaymentMethod { cash, bank, card, cheque, online }

class CustomerPaymentModel {
  final String id;
  final String companyId;
  final String paymentNumber;
  final String customerId;
  final String customerName;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? bankAccountId; // Linked to Banking module
  final DateTime paymentDate;
  final CustomerPaymentMethod paymentMethod;
  final String? referenceNumber;
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final bool isPosted;
  final String? journalEntryId;
  final String? approvalStatus;

  CustomerPaymentModel({
    required this.id,
    required this.companyId,
    required this.paymentNumber,
    required this.customerId,
    required this.customerName,
    this.invoiceId,
    this.invoiceNumber,
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
      'customerId': customerId,
      'customerName': customerName,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
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

  factory CustomerPaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerPaymentModel(
      id: id,
      companyId: map['companyId'] ?? '',
      paymentNumber: map['paymentNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      invoiceId: map['invoiceId'],
      invoiceNumber: map['invoiceNumber'],
      bankAccountId: map['bankAccountId'],
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      paymentMethod: CustomerPaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => CustomerPaymentMethod.bank,
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
