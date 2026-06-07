import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/models/audit_log_model.dart';

class AuditRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getLogsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('auditLogs');
  }

  Future<void> logAction(AuditLogModel log) async {
    if (log.companyId.isEmpty) return;
    await _getLogsRef(log.companyId).add(log.toFirestore());
  }

  Stream<List<AuditLogModel>> getLogs(String companyId) {
    return _getLogsRef(companyId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogModel.fromFirestore(doc))
              .toList(),
        );
  }
}
