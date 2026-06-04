import 'package:ledgixerp/core/models/audit_log_model.dart';
import 'package:ledgixerp/core/repositories/audit_repository.dart';
import 'package:uuid/uuid.dart';

class AuditService {
  final AuditRepository _repository = AuditRepository();

  Future<void> log({
    required String companyId,
    required String userId,
    required String action,
    required String module,
    required String documentId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    final log = AuditLogModel(
      id: const Uuid().v4(),
      companyId: companyId,
      userId: userId,
      action: action,
      module: module,
      documentId: documentId,
      oldData: oldData,
      newData: newData,
      timestamp: DateTime.now(),
    );

    await _repository.logAction(log);
  }
}
