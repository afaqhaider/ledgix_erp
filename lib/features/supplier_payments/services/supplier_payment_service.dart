import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import '../../settings/services/financial_settings_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';

class SupplierPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();
  final _postingService = AccountingPostingService();
  final _approvalService = ApprovalService();

  CollectionReference _getPaymentsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments');
  }

  Stream<List<SupplierPaymentModel>> getPayments(String companyId) {
    return _getPaymentsRef(
      companyId,
    ).orderBy('paymentDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SupplierPaymentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<String> generateNextPaymentNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(
      companyId,
      'supplierPayment',
    );
  }

  Future<void> addPayment(
    SupplierPaymentModel payment,
    AppUser user, {
    bool shouldPost = false,
  }) async {
    if (shouldPost &&
        await _settingsService.isPeriodLocked(
          payment.companyId,
          payment.paymentDate,
        )) {
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
    SupplierPaymentModel paymentToProcess = payment;
    if (!actualPost) {
      paymentToProcess = payment.copyWith(
        isPosted: false,
        journalEntryId: null,
      );
    }

    String? initialApprovalStatus = 'pending';
    if (actualPost) {
      initialApprovalStatus = 'approved';
    }

    String? paymentId;
    String? finalPaymentNumber;

    await _firestore.runTransaction((transaction) async {
      // 1. Generate the actual document number and increment counter within transaction
      finalPaymentNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            paymentToProcess.companyId,
            'supplierPayment',
            transaction: transaction,
          );

      final docRef = _getPaymentsRef(paymentToProcess.companyId).doc();
      paymentId = docRef.id;

      final paymentToSave = paymentToProcess.copyWith(
        id: docRef.id,
        paymentNumber: finalPaymentNumber!,
        isPosted: false, // Ensure false initially; PostingService will set it to true
        approvalStatus: initialApprovalStatus,
      );

      // 2. Save the payment
      transaction.set(docRef, paymentToSave.toMap());
    });

    if (actualPost && paymentId != null) {
      try {
        final doc = await _getPaymentsRef(
          paymentToProcess.companyId,
        ).doc(paymentId).get();
        final savedPayment = SupplierPaymentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        await _postingService.postSupplierPayment(
          paymentToProcess.companyId,
          savedPayment,
          user,
        );

        // TODO: onTransactionPosted('supplierPayment', paymentId!)
      } catch (e, stack) {
        debugPrint(
          'CRITICAL: Auto-posting failed for supplier payment $paymentId: $e',
        );
        debugPrint(stack.toString());
        throw Exception(
          'Supplier payment saved successfully as $paymentId, but auto-posting failed. Error: $e',
        );
      }
    } else if (shouldPost && !isAuthorizedToPost && paymentId != null) {
      await _approvalService.submitForApproval(
        user: user,
        companyId: paymentToProcess.companyId,
        sourceType: 'supplier_payment',
        sourceId: paymentId!,
        sourceNumber: finalPaymentNumber ?? 'AUTO',
        amount: paymentToProcess.amount,
      );
    }
  }

  Future<void> deletePayment(String companyId, String paymentId) async {
    final doc = await _getPaymentsRef(companyId).doc(paymentId).get();
    if (!doc.exists) return;

    final payment = SupplierPaymentModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
    if (payment.isPosted) {
      throw Exception(
        'Cannot delete a posted payment. Reverse the entry via Journal if needed.',
      );
    }

    await _getPaymentsRef(companyId).doc(paymentId).delete();
  }
}
