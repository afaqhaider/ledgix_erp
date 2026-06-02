import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';
import 'package:ledgixerp/features/notifications/services/notification_service.dart';
import 'package:ledgixerp/features/notifications/models/notification_model.dart';

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

  Future<void> submitForApproval(ApprovalRequestModel request) async {
    final batch = _firestore.batch();

    // 1. Create approval request
    final docRef = _getRef(request.companyId).doc();
    batch.set(docRef, request.toMap()..['id'] = docRef.id);

    // 2. Update source document status if needed (e.g. set to 'pending_approval')
    // We'll handle this in the UI or by passing a callback

    await batch.commit();

    // 3. Notify owners/admins
    final ownersSnap = await _firestore.collection('users')
        .where('companyId', isEqualTo: request.companyId)
        .where('role', whereIn: ['owner', 'admin'])
        .get();

    for (var doc in ownersSnap.docs) {
      if (doc.id != request.requestedByUserId) { // Don't notify self
        await _notificationService.sendNotification(
          userId: doc.id,
          companyId: request.companyId,
          title: 'Approval Requested',
          message: '${request.requestedByUserName} submitted a ${request.sourceType} (${request.sourceNumber}) for approval.',
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
      actionType: 'create',
      module: 'approvals',
      documentId: docRef.id,
      documentNumber: request.sourceNumber,
      description:
          'Submitted ${request.sourceType} ${request.sourceNumber} for approval',
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

    // 1. Update approval request
    batch.update(_getRef(companyId).doc(approvalId), {
      'status': status.name,
      'approverUserId': approverId,
      'approverUserName': approverName,
      'actionedAt': FieldValue.serverTimestamp(),
      'notes': notes,
    });

    // 2. Update source document status
    String collectionName;
    switch (sourceType) {
      case 'salesInvoice':
        collectionName = 'salesInvoices';
        break;
      case 'quotation':
        collectionName = 'quotations';
        break;
      case 'purchaseOrder':
        collectionName = 'purchaseOrders';
        break;
      case 'supplierPayment':
        collectionName = 'supplierPayments';
        break;
      case 'customerPayment':
        collectionName = 'customerPayments';
        break;
      case 'journalEntry':
        collectionName = 'journalEntries';
        break;
      default:
        throw 'Unknown source type: $sourceType';
    }

    batch.update(
      _firestore
          .collection('companies')
          .doc(companyId)
          .collection(collectionName)
          .doc(sourceId),
      {'approvalStatus': status.name},
    );

    await batch.commit();

    // 3. Notify the requester
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
