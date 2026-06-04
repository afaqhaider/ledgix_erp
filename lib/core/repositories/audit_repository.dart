import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/models/audit_log_model.dart';

class AuditRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logAction(AuditLogModel log) async {
    await _firestore.collection('audit_logs').add(log.toFirestore());
  }

  Stream<List<AuditLogModel>> getLogs(String companyId) {
    return _firestore
        .collection('audit_logs')
        .where('companyId', isEqualTo: companyId)
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
