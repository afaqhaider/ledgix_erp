import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, bank, card, cheque, online }

enum SupplierPaymentType {
  againstRef('Against Ref'),
  onAccount('On Account'),
  advance('Advance');

  final String label;
  const SupplierPaymentType(this.label);
}

class BillAllocation {
  final String billId;
  final String billNumber;
  final double amount;

  BillAllocation({
    required this.billId,
    required this.billNumber,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
    'billId': billId,
    'billNumber': billNumber,
    'amount': amount,
  };

  factory BillAllocation.fromMap(Map<String, dynamic> map) => BillAllocation(
    billId: map['billId'] ?? '',
    billNumber: map['billNumber'] ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
  );
}

class SupplierPaymentModel {
  final String id;
  final String companyId;
  final String paymentNumber;
  final String supplierId;
  final String supplierName;
  final SupplierPaymentType paymentType;
  final String? billId;
  final String? billNumber;
  final List<BillAllocation> allocations;
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

  // Job Link
  final String? jobId;
  final String? jobNumber;
  final String? jobName;

  SupplierPaymentModel({
    required this.id,
    required this.companyId,
    required this.paymentNumber,
    required this.supplierId,
    required this.supplierName,
    this.billId,
    this.billNumber,
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
    this.paymentType = SupplierPaymentType.onAccount,
    this.allocations = const [],
    this.jobId,
    this.jobNumber,
    this.jobName,
  });

  SupplierPaymentModel copyWith({
    String? id,
    String? companyId,
    String? paymentNumber,
    String? supplierId,
    String? supplierName,
    SupplierPaymentType? paymentType,
    String? billId,
    String? billNumber,
    List<BillAllocation>? allocations,
    String? purchaseOrderId,
    String? purchaseOrderNumber,
    String? bankAccountId,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? referenceNumber,
    double? amount,
    String? notes,
    DateTime? createdAt,
    bool? isPosted,
    String? journalEntryId,
    String? approvalStatus,
    String? jobId,
    String? jobNumber,
    String? jobName,
  }) {
    return SupplierPaymentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      paymentType: paymentType ?? this.paymentType,
      billId: billId ?? this.billId,
      billNumber: billNumber ?? this.billNumber,
      allocations: allocations ?? this.allocations,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
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
      jobId: jobId ?? this.jobId,
      jobNumber: jobNumber ?? this.jobNumber,
      jobName: jobName ?? this.jobName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'paymentNumber': paymentNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'paymentType': paymentType.name,
      'billId': billId,
      'billNumber': billNumber,
      'allocations': allocations.map((e) => e.toMap()).toList(),
      'purchaseOrderId': purchaseOrderId,
      'purchaseOrderNumber': purchaseOrderNumber,
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
      'jobId': jobId,
      'jobNumber': jobNumber,
      'jobName': jobName,
    };
  }

  factory SupplierPaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return SupplierPaymentModel(
      id: id,
      companyId: map['companyId'] ?? '',
      paymentNumber: map['paymentNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      paymentType: SupplierPaymentType.values.firstWhere(
        (e) => e.name == (map['paymentType'] ?? ''),
        orElse: () => SupplierPaymentType.onAccount,
      ),
      billId: map['billId'],
      billNumber: map['billNumber'],
      allocations: (map['allocations'] as List? ?? [])
          .map((e) => BillAllocation.fromMap(e as Map<String, dynamic>))
          .toList(),
      purchaseOrderId: map['purchaseOrderId'],
      purchaseOrderNumber: map['purchaseOrderNumber'],
      bankAccountId: map['bankAccountId'],
      paymentDate:
          (map['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.bank,
      ),
      referenceNumber: map['referenceNumber'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPosted: map['isPosted'] ?? false,
      journalEntryId: map['journalEntryId'],
      approvalStatus: map['approvalStatus'],
      jobId: map['jobId'],
      jobNumber: map['jobNumber'],
      jobName: map['jobName'],
    );
  }
}
