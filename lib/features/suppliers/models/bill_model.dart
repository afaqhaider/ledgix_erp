import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/models/attachment_model.dart';

enum BillStatus {
  draft,
  pendingApproval,
  approved,
  posted,
  partiallyPaid,
  paid,
  voided,
}

class BillModel {
  final String id;
  final String companyId;
  final String billNumber;
  final String supplierId;
  final String supplierName;
  final DateTime billDate;
  final DateTime dueDate;
  final List<BillLineItemModel> items;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final BillStatus status;
  final String? notes;
  final String? reference;
  final bool isPosted;
  final String? journalEntryId;
  final List<AttachmentModel> attachments;
  final DateTime createdAt;
  final String? approvalStatus; // pending, approved, rejected

  // Job Link (Header)
  final String? jobId;
  final String? jobNumber;
  final String? jobName;

  BillModel({
    required this.id,
    required this.companyId,
    required this.billNumber,
    required this.supplierId,
    required this.supplierName,
    required this.billDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    this.amountPaid = 0.0,
    required this.balanceDue,
    this.status = BillStatus.draft,
    this.notes,
    this.reference,
    this.isPosted = false,
    this.journalEntryId,
    this.attachments = const [],
    required this.createdAt,
    this.approvalStatus,
    this.jobId,
    this.jobNumber,
    this.jobName,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'billNumber': billNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'billDate': Timestamp.fromDate(billDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'items': items.map((x) => x.toMap()).toList(),
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'balanceDue': balanceDue,
      'status': status.name,
      'notes': notes,
      'reference': reference,
      'isPosted': isPosted,
      'journalEntryId': journalEntryId,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'approvalStatus': approvalStatus,
      'jobId': jobId,
      'jobNumber': jobNumber,
      'jobName': jobName,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map, String id) {
    return BillModel(
      id: id,
      companyId: map['companyId'] ?? '',
      billNumber: map['billNumber'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      billDate: (map['billDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items:
          (map['items'] as List?)
              ?.map((x) => BillLineItemModel.fromMap(x))
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (map['vatAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balanceDue'] as num?)?.toDouble() ?? 0.0,
      status: BillStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BillStatus.draft,
      ),
      notes: map['notes'],
      reference: map['reference'],
      isPosted: map['isPosted'] ?? false,
      journalEntryId: map['journalEntryId'],
      attachments:
          (map['attachments'] as List?)
              ?.map((x) => AttachmentModel.fromMap(x))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvalStatus: map['approvalStatus'],
      jobId: map['jobId'],
      jobNumber: map['jobNumber'],
      jobName: map['jobName'],
    );
  }

  BillModel copyWith({
    String? id,
    String? companyId,
    String? billNumber,
    String? supplierId,
    String? supplierName,
    DateTime? billDate,
    DateTime? dueDate,
    List<BillLineItemModel>? items,
    double? subtotal,
    double? vatAmount,
    double? totalAmount,
    double? amountPaid,
    double? balanceDue,
    BillStatus? status,
    String? notes,
    String? reference,
    bool? isPosted,
    String? journalEntryId,
    List<AttachmentModel>? attachments,
    DateTime? createdAt,
    String? approvalStatus,
    String? jobId,
    String? jobNumber,
    String? jobName,
  }) {
    return BillModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      billNumber: billNumber ?? this.billNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      billDate: billDate ?? this.billDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reference: reference ?? this.reference,
      isPosted: isPosted ?? this.isPosted,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      jobId: jobId ?? this.jobId,
      jobNumber: jobNumber ?? this.jobNumber,
      jobName: jobName ?? this.jobName,
    );
  }
}

class BillLineItemModel {
  final String? productId;
  final String accountId;
  final String accountName;
  final String description;
  final String? unit;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double lineSubtotal;
  final double lineVat;
  final double lineTotal;

  // Job Link
  final String? jobId;
  final String? jobNumber;
  final String? jobName;

  BillLineItemModel({
    this.productId,
    required this.accountId,
    required this.accountName,
    required this.description,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.lineSubtotal,
    required this.lineVat,
    required this.lineTotal,
    this.jobId,
    this.jobNumber,
    this.jobName,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'accountId': accountId,
      'accountName': accountName,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
      'lineSubtotal': lineSubtotal,
      'lineVat': lineVat,
      'lineTotal': lineTotal,
      'jobId': jobId,
      'jobNumber': jobNumber,
      'jobName': jobName,
    };
  }

  factory BillLineItemModel.fromMap(Map<String, dynamic> map) {
    return BillLineItemModel(
      productId: map['productId'],
      accountId: map['accountId'] ?? '',
      accountName: map['accountName'] ?? '',
      description: map['description'] ?? '',
      unit: map['unit'],
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      vatRate: (map['vatRate'] as num?)?.toDouble() ?? 0.0,
      lineSubtotal: (map['lineSubtotal'] as num?)?.toDouble() ?? 0.0,
      lineVat: (map['lineVat'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['lineTotal'] as num?)?.toDouble() ?? 0.0,
      jobId: map['jobId'],
      jobNumber: map['jobNumber'],
      jobName: map['jobName'],
    );
  }
}
