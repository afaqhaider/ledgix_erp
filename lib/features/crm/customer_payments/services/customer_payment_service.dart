import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import '../../../settings/services/financial_settings_service.dart';

class CustomerPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

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

  Future<void> addPayment(CustomerPaymentModel payment) async {
    if (await _settingsService.isPeriodLocked(
      payment.companyId,
      payment.paymentDate,
    )) {
      throw Exception('Accounting period for this date is locked.');
    }

    await _firestore.runTransaction((transaction) async {
      // Generate final number and increment
      final finalNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            payment.companyId,
            'receipt',
            transaction: transaction,
          );

      final payRef = _getRef(payment.companyId).doc();
      final paymentToSave = payment.copyWith(
        id: payRef.id,
        paymentNumber: finalNumber,
        isPosted: false, // Ensure it's not posted by default
      );

      transaction.set(payRef, paymentToSave.toMap());
      
      // PRIORITY 3: We no longer update invoice balances here.
      // It will be handled in AccountingPostingService upon posting.
    });
  }

  Future<void> updatePayment(CustomerPaymentModel payment) async {
    final doc = await _getRef(payment.companyId).doc(payment.id).get();
    if (doc.exists && (doc.data() as Map<String, dynamic>)['isPosted'] == true) {
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
