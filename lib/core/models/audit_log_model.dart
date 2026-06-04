import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String companyId;
  final String userId;
  final String action; // 'create', 'update', 'delete', 'post'
  final String module; // 'sales', 'accounting', etc.
  final String documentId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.action,
    required this.module,
    required this.documentId,
    this.oldData,
    this.newData,
    required this.timestamp,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      module: data['module'] ?? '',
      documentId: data['documentId'] ?? '',
      oldData: data['oldData'],
      newData: data['newData'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'userId': userId,
      'action': action,
      'module': module,
      'documentId': documentId,
      'oldData': oldData,
      'newData': newData,
      'timestamp': timestamp,
    };
  }
}
