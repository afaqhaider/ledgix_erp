import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/audit/audit_log_model.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('auditLogs');
  }

  Future<void> log({
    required String companyId,
    required String userId,
    required String userName,
    required String actionType,
    required String module,
    required String documentId,
    String? documentNumber,
    required String description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? deviceInfo,
  }) async {
    final docRef = _getRef(companyId).doc();
    final log = AuditLogModel(
      id: docRef.id,
      companyId: companyId,
      userId: userId,
      userName: userName,
      actionType: actionType,
      module: module,
      documentId: documentId,
      documentNumber: documentNumber,
      description: description,
      oldValues: oldValues,
      newValues: newValues,
      createdAt: DateTime.now(),
      deviceInfo: deviceInfo,
    );

    await docRef.set(log.toMap());
  }

  Stream<List<AuditLogModel>> getLogs(
    String companyId, {
    String? userId,
    String? module,
    String? actionType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _getRef(companyId).orderBy('createdAt', descending: true);

    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (module != null) query = query.where('module', isEqualTo: module);
    if (actionType != null) {
      query = query.where('actionType', isEqualTo: actionType);
    }

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }

    return query.limit(100).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AuditLogModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }
}
