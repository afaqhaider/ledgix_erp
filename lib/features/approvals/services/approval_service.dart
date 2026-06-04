import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/features/approvals/models/approval_rule_model.dart';

class ApprovalService {
  final _db = FirebaseFirestore.instance;
  final _auditService = AuditService();

  // Rules Management
  Stream<List<ApprovalRuleModel>> getRules(String companyId) {
    return _db
        .collection('companies')
        .doc(companyId)
        .collection('approval_rules')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ApprovalRuleModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> saveRule(ApprovalRuleModel rule) async {
    final docRef = _db
        .collection('companies')
        .doc(rule.companyId)
        .collection('approval_rules')
        .doc(rule.id.isEmpty ? null : rule.id);

    final data = rule.toMap();
    if (rule.id.isEmpty) {
      data['id'] = docRef.id;
    }
    await docRef.set(data, SetOptions(merge: true));
  }

  // Approval Process
  Future<ApprovalRuleModel?> findMatchingRule({
    required String companyId,
    required ApprovalModule module,
    required double amount,
  }) async {
    final snapshot = await _db
        .collection('companies')
        .doc(companyId)
        .collection('approval_rules')
        .where('module', isEqualTo: module.name)
        .where('isEnabled', isEqualTo: true)
        .get();

    final rules = snapshot.docs
        .map((doc) => ApprovalRuleModel.fromMap(doc.data(), doc.id))
        .toList();

    for (var rule in rules) {
      if (amount >= rule.minAmount && amount <= rule.maxAmount) {
        return rule;
      }
    }
    return null;
  }

  Future<String?> submitForApproval({
    required AppUser user,
    required String companyId,
    required String sourceType,
    required String sourceId,
    required String sourceNumber,
    required double amount,
  }) async {
    final module = _getModuleFromType(sourceType);
    if (module == null) return null;

    final rule = await findMatchingRule(
      companyId: companyId,
      module: module,
      amount: amount,
    );

    if (rule == null || rule.requiredApproverRoles.isEmpty) {
      return null; // No approval required
    }

    final docRef = _db
        .collection('companies')
        .doc(companyId)
        .collection('approval_requests')
        .doc();

    final request = ApprovalRequestModel(
      id: docRef.id,
      companyId: companyId,
      sourceType: sourceType,
      sourceId: sourceId,
      sourceNumber: sourceNumber,
      amount: amount,
      requestedByUserId: user.uid,
      requestedByUserName: user.fullName,
      requestedAt: DateTime.now(),
      status: ApprovalStatus.pending,
      currentApproverRoleId: rule.requiredApproverRoles.first.name,
    );

    await docRef.set(request.toMap());

    // Update source document status
    await _db
        .collection('companies')
        .doc(companyId)
        .collection(_getCollectionName(sourceType))
        .doc(sourceId)
        .update({'approvalStatus': 'pending', 'approvalRequestId': docRef.id});

    await _auditService.log(
      companyId: companyId,
      userId: user.uid,
      userName: user.fullName,
      actionType: 'approval_requested',
      module: sourceType,
      documentId: sourceId,
      description: 'Submitted $sourceNumber for approval (Amount: $amount)',
    );

    return docRef.id;
  }

  Future<void> takeAction({
    required AppUser user,
    required String requestId,
    required ApprovalStatus action,
    String? comments,
  }) async {
    final docRef = _db
        .collection('companies')
        .doc(user.companyId!)
        .collection('approval_requests')
        .doc(requestId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final request = ApprovalRequestModel.fromMap(snapshot.data()!, requestId);

    final historyItem = ApprovalHistoryItem(
      userId: user.uid,
      userName: user.fullName,
      action: action,
      timestamp: DateTime.now(),
      comments: comments,
    );

    final updatedHistory = [...request.history, historyItem];

    await docRef.update({
      'status': action.name,
      'history': updatedHistory.map((e) => e.toMap()).toList(),
      'currentApproverRoleId': null, // For now simplified to one level
    });

    // Update source document
    String mappedStatus = 'draft';
    if (action == ApprovalStatus.approved) mappedStatus = 'approved';
    if (action == ApprovalStatus.rejected) mappedStatus = 'rejected';
    if (action == ApprovalStatus.returned) mappedStatus = 'correction';

    await _db
        .collection('companies')
        .doc(user.companyId!)
        .collection(_getCollectionName(request.sourceType))
        .doc(request.sourceId)
        .update({'approvalStatus': mappedStatus});

    await _auditService.log(
      companyId: user.companyId!,
      userId: user.uid,
      userName: user.fullName,
      actionType: 'approval_${action.name}',
      module: request.sourceType,
      documentId: request.sourceId,
      description:
          '${action.name.toUpperCase()} document ${request.sourceNumber}. Comments: $comments',
    );
  }

  Stream<List<ApprovalRequestModel>> getPendingRequests(
    String companyId,
    String roleName,
  ) {
    return _db
        .collection('companies')
        .doc(companyId)
        .collection('approval_requests')
        .where('status', isEqualTo: 'pending')
        .where('currentApproverRoleId', isEqualTo: roleName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ApprovalRequestModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  ApprovalModule? _getModuleFromType(String type) {
    switch (type) {
      case 'quotation':
        return ApprovalModule.quotations;
      case 'sales_invoice':
        return ApprovalModule.salesInvoices;
      case 'customer_payment':
        return ApprovalModule.customerPayments;
      case 'purchase_order':
        return ApprovalModule.purchaseOrders;
      case 'supplier_payment':
        return ApprovalModule.supplierPayments;
      case 'journal_entry':
        return ApprovalModule.journalEntries;
      case 'supplier_bill':
        return ApprovalModule.supplierBills;
      default:
        return null;
    }
  }

  String _getCollectionName(String type) {
    switch (type) {
      case 'quotation':
        return 'quotations';
      case 'sales_invoice':
        return 'invoices';
      case 'customer_payment':
        return 'customer_payments';
      case 'purchase_order':
        return 'purchase_orders';
      case 'supplier_payment':
        return 'supplier_payments';
      case 'journal_entry':
        return 'journal_entries';
      case 'supplier_bill':
        return 'supplier_bills';
      default:
        return type;
    }
  }
}
