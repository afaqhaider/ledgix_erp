import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseVoucherStatus {
  draft('Draft'),
  posted('Posted'),
  voided('Voided'),
  reversed('Reversed');

  final String label;
  const ExpenseVoucherStatus(this.label);
}

class ExpenseVoucherLine {
  final String accountId;
  final String accountName;
  final String description;
  final double amount;
  final bool hasVat;
  final double vatAmount;
  final double total;

  // Job Link
  final String? jobId;
  final String? jobNumber;
  final String? jobName;

  ExpenseVoucherLine({
    required this.accountId,
    required this.accountName,
    required this.description,
    required this.amount,
    this.hasVat = false,
    this.vatAmount = 0.0,
    required this.total,
    this.jobId,
    this.jobNumber,
    this.jobName,
  });

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'description': description,
      'amount': amount,
      'hasVat': hasVat,
      'vatAmount': vatAmount,
      'total': total,
      'jobId': jobId,
      'jobNumber': jobNumber,
      'jobName': jobName,
    };
  }

  factory ExpenseVoucherLine.fromMap(Map<String, dynamic> map) {
    return ExpenseVoucherLine(
      accountId: map['accountId'] ?? '',
      accountName: map['accountName'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      hasVat: map['hasVat'] ?? false,
      vatAmount: (map['vatAmount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      jobId: map['jobId'],
      jobNumber: map['jobNumber'],
      jobName: map['jobName'],
    );
  }
}

class ExpenseVoucherModel {
  final String id;
  final String companyId;
  final String voucherNumber;
  final DateTime date;
  final String fromAccountId; // Bank or Cash
  final String fromAccountName;
  final String description;
  final List<ExpenseVoucherLine> lines;
  final double totalAmount;
  final double totalVat;
  final ExpenseVoucherStatus status;
  final String createdByUserId;
  final String? postedByUserId;
  final DateTime createdAt;
  final DateTime? postedAt;
  final String? approvalStatus; // pending, approved, rejected

  // Job Link (Header)
  final String? jobId;
  final String? jobNumber;
  final String? jobName;

  ExpenseVoucherModel({
    required this.id,
    required this.companyId,
    required this.voucherNumber,
    required this.date,
    required this.fromAccountId,
    required this.fromAccountName,
    required this.description,
    required this.lines,
    required this.totalAmount,
    required this.totalVat,
    this.status = ExpenseVoucherStatus.draft,
    required this.createdByUserId,
    this.postedByUserId,
    required this.createdAt,
    this.postedAt,
    this.approvalStatus,
    this.jobId,
    this.jobNumber,
    this.jobName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'voucherNumber': voucherNumber,
      'date': Timestamp.fromDate(date),
      'fromAccountId': fromAccountId,
      'fromAccountName': fromAccountName,
      'description': description,
      'lines': lines.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'totalVat': totalVat,
      'status': status.name,
      'createdByUserId': createdByUserId,
      'postedByUserId': postedByUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'postedAt': postedAt != null ? Timestamp.fromDate(postedAt!) : null,
      'approvalStatus': approvalStatus,
      'jobId': jobId,
      'jobNumber': jobNumber,
      'jobName': jobName,
    };
  }

  factory ExpenseVoucherModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseVoucherModel(
      id: id,
      companyId: map['companyId'] ?? '',
      voucherNumber: map['voucherNumber'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      fromAccountId: map['fromAccountId'] ?? '',
      fromAccountName: map['fromAccountName'] ?? '',
      description: map['description'] ?? '',
      lines: List<ExpenseVoucherLine>.from(
        (map['lines'] as List? ?? []).map((x) => ExpenseVoucherLine.fromMap(x)),
      ),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalVat: (map['totalVat'] as num?)?.toDouble() ?? 0.0,
      status: ExpenseVoucherStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExpenseVoucherStatus.draft,
      ),
      createdByUserId: map['createdByUserId'] ?? '',
      postedByUserId: map['postedByUserId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      postedAt: (map['postedAt'] as Timestamp?)?.toDate(),
      approvalStatus: map['approvalStatus'],
      jobId: map['jobId'],
      jobNumber: map['jobNumber'],
      jobName: map['jobName'],
    );
  }

  ExpenseVoucherModel copyWith({
    String? id,
    String? companyId,
    String? voucherNumber,
    DateTime? date,
    String? fromAccountId,
    String? fromAccountName,
    String? description,
    List<ExpenseVoucherLine>? lines,
    double? totalAmount,
    double? totalVat,
    ExpenseVoucherStatus? status,
    String? createdByUserId,
    String? postedByUserId,
    DateTime? createdAt,
    DateTime? postedAt,
    String? approvalStatus,
    String? jobId,
    String? jobNumber,
    String? jobName,
  }) {
    return ExpenseVoucherModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      date: date ?? this.date,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      fromAccountName: fromAccountName ?? this.fromAccountName,
      description: description ?? this.description,
      lines: lines ?? this.lines,
      totalAmount: totalAmount ?? this.totalAmount,
      totalVat: totalVat ?? this.totalVat,
      status: status ?? this.status,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      createdAt: createdAt ?? this.createdAt,
      postedAt: postedAt ?? this.postedAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      jobId: jobId ?? this.jobId,
      jobNumber: jobNumber ?? this.jobNumber,
      jobName: jobName ?? this.jobName,
    );
  }
}
