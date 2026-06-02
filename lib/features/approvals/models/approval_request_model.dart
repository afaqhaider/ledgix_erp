import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus { pending, approved, rejected }

class ApprovalRequestModel {
  final String id;
  final String companyId;
  final String
  sourceType; // quotation, salesInvoice, purchaseOrder, supplierPayment, journalEntry
  final String sourceId;
  final String sourceNumber;
  final String requestedByUserId;
  final String requestedByUserName;
  final String? approverUserId;
  final String? approverUserName;
  final ApprovalStatus status;
  final DateTime requestedAt;
  final DateTime? actionedAt;
  final String? notes;

  ApprovalRequestModel({
    required this.id,
    required this.companyId,
    required this.sourceType,
    required this.sourceId,
    required this.sourceNumber,
    required this.requestedByUserId,
    required this.requestedByUserName,
    this.approverUserId,
    this.approverUserName,
    this.status = ApprovalStatus.pending,
    required this.requestedAt,
    this.actionedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sourceNumber': sourceNumber,
      'requestedByUserId': requestedByUserId,
      'requestedByUserName': requestedByUserName,
      'approverUserId': approverUserId,
      'approverUserName': approverUserName,
      'status': status.name,
      'requestedAt': requestedAt,
      'actionedAt': actionedAt,
      'notes': notes,
    };
  }

  factory ApprovalRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ApprovalRequestModel(
      id: id,
      companyId: map['companyId'] ?? '',
      sourceType: map['sourceType'] ?? '',
      sourceId: map['sourceId'] ?? '',
      sourceNumber: map['sourceNumber'] ?? '',
      requestedByUserId: map['requestedByUserId'] ?? '',
      requestedByUserName: map['requestedByUserName'] ?? '',
      approverUserId: map['approverUserId'],
      approverUserName: map['approverUserName'],
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      actionedAt: (map['actionedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'],
    );
  }
}
