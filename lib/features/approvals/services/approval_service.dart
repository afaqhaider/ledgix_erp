import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';
import 'package:ledgixerp/features/notifications/services/notification_service.dart';
import 'package:ledgixerp/features/notifications/models/notification_model.dart';
import 'package:ledgixerp/core/auth/user_role.dart';

class ApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _auditService = AuditService();
  final _notificationService = NotificationService();

  CollectionReference _getRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('approvals');
  }

  Stream<List<ApprovalRequestModel>> getPendingApprovals(String companyId) {
    return _getRef(companyId)
        .where('status', isEqualTo: ApprovalStatus.pending.name)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ApprovalRequestModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Stream<List<ApprovalRequestModel>> getMyRequests(
    String companyId,
    String userId,
  ) {
    return _getRef(companyId)
        .where('requestedByUserId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ApprovalRequestModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  Future<void> submitForApproval(
    ApprovalRequestModel request, {
    required UserRole requesterRole,
  }) async {
    // 1. AUTO-APPROVE Logic: If requester is Owner or Finance Manager (rank >= 80)
    if (requesterRole.rank >= 80) {
      await _autoApprove(request);
      return;
    }

    final batch = _firestore.batch();

    // 2. Create approval request
    final docRef = _getRef(request.companyId).doc();
    batch.set(docRef, request.toMap()..['id'] = docRef.id);

    // 3. Update source document status to 'pendingApproval'
    final sourceCollection = _getCollectionForType(request.sourceType);
    batch.update(
      _firestore
          .collection('companies')
          .doc(request.companyId)
          .collection(sourceCollection)
          .doc(request.sourceId),
      {'approvalStatus': ApprovalStatus.pending.name},
    );

    await batch.commit();

    // 4. Notify higher roles (Hierarchical Escalation)
    final superiorsSnap = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: request.companyId)
        .get();

    for (var doc in superiorsSnap.docs) {
      final userData = doc.data();
      final roleName = userData['role'] ?? 'dataEntry';
      final role = UserRole.values.firstWhere(
        (e) => e.name == roleName,
        orElse: () => UserRole.dataEntry,
      );

      if (role.rank > requesterRole.rank &&
          doc.id != request.requestedByUserId) {
        await _notificationService.sendNotification(
          userId: doc.id,
          companyId: request.companyId,
          title: 'Approval Required',
          message:
              '${request.requestedByUserName} submitted ${request.sourceType} ${request.sourceNumber} for review.',
          type: NotificationType.approval,
          relatedDocId: docRef.id,
          relatedDocType: 'approval',
        );
      }
    }

    await _auditService.log(
      companyId: request.companyId,
      userId: request.requestedByUserId,
      userName: request.requestedByUserName,
      actionType: 'submit_approval',
      module: 'approvals',
      documentId: docRef.id,
      documentNumber: request.sourceNumber,
      description:
          'Submitted ${request.sourceType} ${request.sourceNumber} for approval',
    );
  }

  Future<void> _autoApprove(ApprovalRequestModel request) async {
    final batch = _firestore.batch();
    final sourceCollection = _getCollectionForType(request.sourceType);

    batch.update(
      _firestore
          .collection('companies')
          .doc(request.companyId)
          .collection(sourceCollection)
          .doc(request.sourceId),
      {'approvalStatus': ApprovalStatus.approved.name},
    );

    final docRef = _getRef(request.companyId).doc();
    batch.set(
      docRef,
      request.toMap()..addAll({
        'id': docRef.id,
        'status': ApprovalStatus.approved.name,
        'approverUserId': request.requestedByUserId,
        'approverUserName': '${request.requestedByUserName} (Auto)',
        'actionedAt': FieldValue.serverTimestamp(),
        'notes': 'Auto-approved based on role rank.',
      }),
    );

    await batch.commit();

    await _auditService.log(
      companyId: request.companyId,
      userId: request.requestedByUserId,
      userName: request.requestedByUserName,
      actionType: 'auto_approve',
      module: 'approvals',
      documentId: request.sourceId,
      documentNumber: request.sourceNumber,
      description:
          'Auto-approved ${request.sourceType} ${request.sourceNumber}',
    );
  }

  Future<void> actionApproval({
    required String companyId,
    required String approvalId,
    required String approverId,
    required String approverName,
    required ApprovalStatus status,
    required String sourceType,
    required String sourceId,
    String? sourceNumber,
    String? notes,
  }) async {
    final batch = _firestore.batch();

    batch.update(_getRef(companyId).doc(approvalId), {
      'status': status.name,
      'approverUserId': approverId,
      'approverUserName': approverName,
      'actionedAt': FieldValue.serverTimestamp(),
      'notes': notes,
    });

    final collectionName = _getCollectionForType(sourceType);

    batch.update(
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection(collectionName)
          .doc(sourceId),
      {'approvalStatus': status.name},
    );

    await batch.commit();

    final reqSnap = await _getRef(companyId).doc(approvalId).get();
    if (reqSnap.exists) {
      final reqData = reqSnap.data() as Map<String, dynamic>;
      final requestedByUserId = reqData['requestedByUserId'];

      await _notificationService.sendNotification(
        userId: requestedByUserId,
        companyId: companyId,
        title: status == ApprovalStatus.approved
            ? 'Request Approved'
            : 'Request Rejected',
        message:
            'Your ${reqData['sourceType']} request (${reqData['sourceNumber']}) was ${status.name} by $approverName.',
        type: NotificationType.approval,
        relatedDocId: sourceId,
        relatedDocType: sourceType,
      );
    }

    await _auditService.log(
      companyId: companyId,
      userId: approverId,
      userName: approverName,
      actionType: status == ApprovalStatus.approved ? 'approve' : 'reject',
      module: 'approvals',
      documentId: approvalId,
      documentNumber: sourceNumber,
      description:
          '${status == ApprovalStatus.approved ? 'Approved' : 'Rejected'} $sourceType $sourceNumber',
    );
  }

  String _getCollectionForType(String sourceType) {
    switch (sourceType) {
      case 'salesInvoice':
        return 'salesInvoices';
      case 'quotation':
        return 'quotations';
      case 'purchaseOrder':
        return 'purchaseOrders';
      case 'supplierPayment':
        return 'supplierPayments';
      case 'customerPayment':
        return 'customerPayments';
      case 'journalEntry':
        return 'journalEntries';
      case 'supplierBill':
        return 'supplierBills';
      default:
        throw 'Unknown source type: $sourceType';
    }
  }

  Future<ApprovalRequestModel?> getRequestBySource(
    String companyId,
    String sourceId,
  ) async {
    final snapshot = await _getRef(
      companyId,
    ).where('sourceId', isEqualTo: sourceId).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return ApprovalRequestModel.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }
}
