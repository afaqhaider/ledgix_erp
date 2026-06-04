import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus { pending, approved, rejected, returned }

class ApprovalHistoryItem {
  final String userId;
  final String userName;
  final ApprovalStatus action;
  final DateTime timestamp;
  final String? comments;

  ApprovalHistoryItem({
    required this.userId,
    required this.userName,
    required this.action,
    required this.timestamp,
    this.comments,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'action': action.name,
      'timestamp': timestamp,
      'comments': comments,
    };
  }

  factory ApprovalHistoryItem.fromMap(Map<String, dynamic> map) {
    return ApprovalHistoryItem(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: ApprovalStatus.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => ApprovalStatus.pending,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      comments: map['comments'],
    );
  }
}

class ApprovalRequestModel {
  final String id;
  final String companyId;
  final String sourceType; // quotation, salesInvoice, purchaseOrder, etc.
  final String sourceId;
  final String sourceNumber;
  final double amount;
  final String requestedByUserId;
  final String requestedByUserName;
  final ApprovalStatus status;
  final DateTime requestedAt;
  final List<ApprovalHistoryItem> history;
  final String? currentApproverRoleId; // The role currently required to approve

  ApprovalRequestModel({
    required this.id,
    required this.companyId,
    required this.sourceType,
    required this.sourceId,
    required this.sourceNumber,
    required this.amount,
    required this.requestedByUserId,
    required this.requestedByUserName,
    this.status = ApprovalStatus.pending,
    required this.requestedAt,
    this.history = const [],
    this.currentApproverRoleId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sourceNumber': sourceNumber,
      'amount': amount,
      'requestedByUserId': requestedByUserId,
      'requestedByUserName': requestedByUserName,
      'status': status.name,
      'requestedAt': requestedAt,
      'history': history.map((e) => e.toMap()).toList(),
      'currentApproverRoleId': currentApproverRoleId,
    };
  }

  factory ApprovalRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ApprovalRequestModel(
      id: id,
      companyId: map['companyId'] ?? '',
      sourceType: map['sourceType'] ?? '',
      sourceId: map['sourceId'] ?? '',
      sourceNumber: map['sourceNumber'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      requestedByUserId: map['requestedByUserId'] ?? '',
      requestedByUserName: map['requestedByUserName'] ?? '',
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      history:
          (map['history'] as List?)
              ?.map((e) => ApprovalHistoryItem.fromMap(e))
              .toList() ??
          [],
      currentApproverRoleId: map['currentApproverRoleId'],
    );
  }
}
