import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import '../../settings/services/financial_settings_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';

class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();
  final _postingService = AccountingPostingService();
  final _approvalService = ApprovalService();

  CollectionReference _getBillsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierBills');
  }

  Stream<List<BillModel>> getBills(String companyId) {
    return _getBillsRef(
      companyId,
    ).orderBy('billDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BillModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<String> previewNextBillNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(companyId, 'bill');
  }

  Future<String> generateNextBillNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(companyId, 'bill');
  }

  Future<void> addBill(
    BillModel bill,
    AppUser user, {
    bool shouldPost = false,
  }) async {
    if (shouldPost &&
        await _settingsService.isPeriodLocked(bill.companyId, bill.billDate)) {
      throw Exception('Accounting period for this date is locked.');
    }

    // Determine initial status based on role and action
    final highRoles = [
      UserRole.owner,
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.accountant,
      UserRole.generalManager,
    ];

    bool isAuthorizedToPost = highRoles.contains(user.role);
    bool actualPost = shouldPost && isAuthorizedToPost;

    // Security Enforcement: Cleanse fields if not authorized to post or not posting
    BillModel billToProcess = bill;
    if (!actualPost) {
      billToProcess = bill.copyWith(
        isPosted: false,
        journalEntryId: null,
        amountPaid: 0.0,
        balanceDue: bill.totalAmount,
      );
    }

    BillStatus initialStatus = BillStatus.draft;
    if (actualPost) {
      initialStatus = BillStatus.posted;
    } else if (shouldPost && !isAuthorizedToPost) {
      initialStatus = BillStatus.pendingApproval;
    }

    String? billId;
    String? finalBillNumber;

    await _firestore.runTransaction((transaction) async {
      // 1. Generate and increment within transaction
      finalBillNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            billToProcess.companyId,
            'bill',
            transaction: transaction,
          );

      final docRef = _getBillsRef(billToProcess.companyId).doc();
      billId = docRef.id;

      final finalBill = billToProcess.copyWith(
        id: docRef.id,
        billNumber: finalBillNumber!,
        status: initialStatus,
      );

      // 2. Save bill
      transaction.set(docRef, finalBill.toMap());
    });

    if (actualPost && billId != null) {
      try {
        final doc = await _getBillsRef(
          billToProcess.companyId,
        ).doc(billId).get();
        final savedBill = BillModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        await _postingService.postSupplierBill(
          billToProcess.companyId,
          savedBill,
          user,
        );

        // TODO: onTransactionPosted('supplier_bill', billId!)
      } catch (e, stack) {
        debugPrint('CRITICAL: Auto-posting failed for bill $billId: $e');
        debugPrint(stack.toString());
        throw Exception(
          'Bill saved successfully as $billId, but auto-posting failed. Error: $e',
        );
      }
    } else if (shouldPost && !isAuthorizedToPost && billId != null) {
      await _approvalService.submitForApproval(
        user: user,
        companyId: billToProcess.companyId,
        sourceType: 'supplier_bill',
        sourceId: billId!,
        sourceNumber: finalBillNumber ?? 'AUTO',
        amount: billToProcess.totalAmount,
      );
    }
  }

  Future<void> updateBillStatus(
    String companyId,
    String billId,
    BillStatus status,
  ) async {
    final doc = await _getBillsRef(companyId).doc(billId).get();
    if (doc.exists &&
        (doc.data() as Map<String, dynamic>)['isPosted'] == true) {
      throw Exception('Cannot update status of a posted bill.');
    }
    await _getBillsRef(companyId).doc(billId).update({'status': status.name});
  }

  Future<void> deleteBill(String companyId, String billId) async {
    final doc = await _getBillsRef(companyId).doc(billId).get();
    if (!doc.exists) return;
    if ((doc.data() as Map<String, dynamic>)['isPosted'] == true) {
      throw Exception('Cannot delete a posted bill. Void it instead.');
    }
    await _getBillsRef(companyId).doc(billId).delete();
  }
}
