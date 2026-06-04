import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerPaymentMethod { cash, bankTransfer, card, cheque, online }

enum ReceiptType { 
  againstRef('Against Ref'), 
  onAccount('On Account'), 
  advance('Advance');

  final String label;
  const ReceiptType(this.label);
}

class PaymentAllocation {
  final String invoiceId;
  final String invoiceNumber;
  final double amount;

  PaymentAllocation({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
    'invoiceId': invoiceId,
    'invoiceNumber': invoiceNumber,
    'amount': amount,
  };

  factory PaymentAllocation.fromMap(Map<String, dynamic> map) => PaymentAllocation(
    invoiceId: map['invoiceId'] ?? '',
    invoiceNumber: map['invoiceNumber'] ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
  );
}

class CustomerPaymentModel {
  final String id;
  final String companyId;
  final String paymentNumber;
  final String customerId;
  final String customerName;
  final ReceiptType receiptType;
  final String? invoiceId; // Keep for backward compatibility/single allocation
  final String? invoiceNumber;
  final List<PaymentAllocation> allocations;
  final String? bankAccountId;
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
    this.receiptType = ReceiptType.onAccount,
    this.allocations = const [],
  });

  CustomerPaymentModel copyWith({
    String? id,
    String? companyId,
    String? paymentNumber,
    String? customerId,
    String? customerName,
    ReceiptType? receiptType,
    String? invoiceId,
    String? invoiceNumber,
    List<PaymentAllocation>? allocations,
    String? bankAccountId,
    DateTime? paymentDate,
    CustomerPaymentMethod? paymentMethod,
    String? referenceNumber,
    double? amount,
    String? notes,
    DateTime? createdAt,
    bool? isPosted,
    String? journalEntryId,
    String? approvalStatus,
  }) {
    return CustomerPaymentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      receiptType: receiptType ?? this.receiptType,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      allocations: allocations ?? this.allocations,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isPosted: isPosted ?? this.isPosted,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'paymentNumber': paymentNumber,
      'customerId': customerId,
      'customerName': customerName,
      'receiptType': receiptType.name,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'allocations': allocations.map((e) => e.toMap()).toList(),
      'bankAccountId': bankAccountId,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod.name,
      'referenceNumber': referenceNumber,
      'amount': amount,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
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
      receiptType: ReceiptType.values.firstWhere(
        (e) => e.name == map['receiptType'],
        orElse: () => ReceiptType.onAccount,
      ),
      allocations: (map['allocations'] as List? ?? [])
          .map((e) => PaymentAllocation.fromMap(e as Map<String, dynamic>))
          .toList(),
      bankAccountId: map['bankAccountId'],
      paymentDate: (map['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: CustomerPaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => CustomerPaymentMethod.bankTransfer,
      ),
      referenceNumber: map['referenceNumber'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPosted: map['isPosted'] ?? false,
      journalEntryId: map['journalEntryId'],
      approvalStatus: map['approvalStatus'],
    );
  }
}
