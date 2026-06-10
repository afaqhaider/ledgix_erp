import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import '../../../settings/services/financial_settings_service.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';

class CustomerPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();
  final _postingService = AccountingPostingService();
  final _approvalService = ApprovalService();

  CollectionReference _getRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments');
  }

  Stream<List<CustomerPaymentModel>> getPayments(String companyId) {
    return _getRef(
      companyId,
    ).orderBy('paymentDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CustomerPaymentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<String> generateNextNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(
      companyId,
      'receipt',
    );
  }

  Future<void> addPayment(
    CustomerPaymentModel payment,
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
    CustomerPaymentModel paymentToProcess = payment;
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
      // Generate final number and increment
      finalPaymentNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            paymentToProcess.companyId,
            'receipt',
            transaction: transaction,
          );

      final payRef = _getRef(paymentToProcess.companyId).doc();
      paymentId = payRef.id;

      final paymentToSave = paymentToProcess.copyWith(
        id: payRef.id,
        paymentNumber: finalPaymentNumber!,
        isPosted: false, // Ensure false initially; PostingService will set it to true
        approvalStatus: initialApprovalStatus,
      );

      transaction.set(payRef, paymentToSave.toMap());
    });

    if (actualPost && paymentId != null) {
      try {
        final doc = await _getRef(
          paymentToProcess.companyId,
        ).doc(paymentId).get();
        final savedPayment = CustomerPaymentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        await _postingService.postCustomerPayment(
          paymentToProcess.companyId,
          savedPayment,
          user,
        );

        // TODO: onTransactionPosted('receipt', paymentId!)
      } catch (e, stack) {
        debugPrint('CRITICAL: Auto-posting failed for receipt $paymentId: $e');
        debugPrint(stack.toString());
        throw Exception(
          'Receipt saved successfully as $paymentId, but auto-posting failed. Error: $e',
        );
      }
    } else if (shouldPost && !isAuthorizedToPost && paymentId != null) {
      await _approvalService.submitForApproval(
        user: user,
        companyId: paymentToProcess.companyId,
        sourceType: 'customer_payment',
        sourceId: paymentId!,
        sourceNumber: finalPaymentNumber ?? 'AUTO',
        amount: paymentToProcess.amount,
      );
    }
  }

  Future<void> updatePayment(CustomerPaymentModel payment) async {
    final doc = await _getRef(payment.companyId).doc(payment.id).get();
    if (doc.exists &&
        (doc.data() as Map<String, dynamic>)['isPosted'] == true) {
      throw Exception('Cannot update a posted payment.');
    }
    await _getRef(payment.companyId).doc(payment.id).update(payment.toMap());
  }

  Future<void> deletePayment(String companyId, String paymentId) async {
    final doc = await _getRef(companyId).doc(paymentId).get();
    if (!doc.exists) return;

    final payment = CustomerPaymentModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
    if (payment.isPosted) {
      throw Exception(
        'Cannot delete a posted payment. Reverse the entry via Journal if needed.',
      );
    }

    // PRIORITY 3: Since balance wasn't updated at creation,
    // we don't need to reverse it here.
    await _getRef(companyId).doc(paymentId).delete();
  }
}
