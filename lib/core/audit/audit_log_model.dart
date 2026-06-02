import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction { create, edit, delete, approve, reject, post, login, logout }

class AuditLogModel {
  final String id;
  final String companyId;
  final String userId;
  final String userName;
  final String actionType; // create, edit, delete, approve, reject, post, login, logout
  final String module; // customers, suppliers, invoices, quotations, payments, journalEntries, chartOfAccounts, approvals, settings
  final String documentId;
  final String? documentNumber;
  final String description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime createdAt;
  final String? deviceInfo;

  AuditLogModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.userName,
    required this.actionType,
    required this.module,
    required this.documentId,
    this.documentNumber,
    required this.description,
    this.oldValues,
    this.newValues,
    required this.createdAt,
    this.deviceInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'userName': userName,
      'actionType': actionType,
      'module': module,
      'documentId': documentId,
      'documentNumber': documentNumber,
      'description': description,
      'oldValues': oldValues,
      'newValues': newValues,
      'createdAt': createdAt,
      'deviceInfo': deviceInfo,
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      id: id,
      companyId: map['companyId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      actionType: map['actionType'] ?? '',
      module: map['module'] ?? '',
      documentId: map['documentId'] ?? '',
      documentNumber: map['documentNumber'],
      description: map['description'] ?? '',
      oldValues: map['oldValues'],
      newValues: map['newValues'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deviceInfo: map['deviceInfo'],
    );
  }
}
