import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/models/attachment_model.dart';

enum InvoiceStatus {
  draft,
  pendingApproval,
  approved,
  posted,
  sent,
  partiallyPaid,
  paid,
  rejected,
  voided,
  reversed,
  cancelled,
}

class InvoiceLineItemModel {
  final String? productId; // Optional link to inventory
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

  InvoiceLineItemModel({
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

  factory InvoiceLineItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItemModel(
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

  // Job Link (Header Level - can be used to set default for lines)
  final String? jobId;
  final String? jobNumber;
  final String? jobName;

  // Customization fields
  final String? invoiceTemplateId;
  final String? primaryBrandColor;
  final String? secondaryBrandColor;
  final String? companyLogoUrl;

  // Posting fields
  final bool isPosted;
  final String? journalEntryId;
  final String? approvalStatus; // pending, approved, rejected
  final DateTime? postedAt;
  final String? postedBy;
  final List<AttachmentModel> attachments;

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
    this.postedAt,
    this.postedBy,
    this.attachments = const [],
    this.jobId,
    this.jobNumber,
    this.jobName,
  });

  InvoiceModel copyWith({
    String? id,
    String? companyId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    DateTime? invoiceDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    List<InvoiceLineItemModel>? items,
    double? subtotal,
    double? vatAmount,
    double? totalAmount,
    double? amountPaid,
    double? balanceDue,
    DateTime? createdAt,
    String? invoiceTemplateId,
    String? primaryBrandColor,
    String? secondaryBrandColor,
    String? companyLogoUrl,
    bool? isPosted,
    String? journalEntryId,
    String? approvalStatus,
    DateTime? postedAt,
    String? postedBy,
    List<AttachmentModel>? attachments,
    String? jobId,
    String? jobNumber,
    String? jobName,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      vatAmount: vatAmount ?? this.vatAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      createdAt: createdAt ?? this.createdAt,
      invoiceTemplateId: invoiceTemplateId ?? this.invoiceTemplateId,
      primaryBrandColor: primaryBrandColor ?? this.primaryBrandColor,
      secondaryBrandColor: secondaryBrandColor ?? this.secondaryBrandColor,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      isPosted: isPosted ?? this.isPosted,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      postedAt: postedAt ?? this.postedAt,
      postedBy: postedBy ?? this.postedBy,
      attachments: attachments ?? this.attachments,
      jobId: jobId ?? this.jobId,
      jobNumber: jobNumber ?? this.jobNumber,
      jobName: jobName ?? this.jobName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.name,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'balanceDue': balanceDue,
      'createdAt': Timestamp.fromDate(createdAt),
      'invoiceTemplateId': invoiceTemplateId,
      'primaryBrandColor': primaryBrandColor,
      'secondaryBrandColor': secondaryBrandColor,
      'companyLogoUrl': companyLogoUrl,
      'isPosted': isPosted,
      'journalEntryId': journalEntryId,
      'approvalStatus': approvalStatus,
      'postedAt': postedAt != null ? Timestamp.fromDate(postedAt!) : null,
      'postedBy': postedBy,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'jobId': jobId,
      'jobNumber': jobNumber,
      'jobName': jobName,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      companyId: map['companyId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      invoiceDate:
          (map['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      items:
          (map['items'] as List<dynamic>?)
              ?.map(
                (i) => InvoiceLineItemModel.fromMap(i as Map<String, dynamic>),
              )
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (map['vatAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balanceDue'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invoiceTemplateId: map['invoiceTemplateId'],
      primaryBrandColor: map['primaryBrandColor'],
      secondaryBrandColor: map['secondaryBrandColor'],
      companyLogoUrl: map['companyLogoUrl'],
      isPosted: map['isPosted'] ?? false,
      journalEntryId: map['journalEntryId'],
      approvalStatus: map['approvalStatus'],
      postedAt: (map['postedAt'] as Timestamp?)?.toDate(),
      postedBy: map['postedBy'],
      attachments:
          (map['attachments'] as List?)
              ?.map((x) => AttachmentModel.fromMap(x))
              .toList() ??
          [],
      jobId: map['jobId'],
      jobNumber: map['jobNumber'],
      jobName: map['jobName'],
    );
  }
}
