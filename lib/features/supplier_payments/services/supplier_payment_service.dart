import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import '../../settings/services/financial_settings_service.dart';

class SupplierPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

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
    return await _settingsService.generateNextDocumentNumber(companyId, 'supplierPayment');
  }

  Future<void> addPayment(SupplierPaymentModel payment) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(payment.companyId, payment.paymentDate)) {
      throw Exception('Accounting period for this date is locked.');
    }
    await _getPaymentsRef(payment.companyId).doc().set(payment.toMap());
  }

  Future<void> deletePayment(String companyId, String paymentId) async {
    final doc = await _getPaymentsRef(companyId).doc(paymentId).get();
    if (!doc.exists) return;

    final payment = SupplierPaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    if (payment.isPosted) {
      throw Exception('Cannot delete a posted payment. Reverse the entry via Journal if needed.');
    }

    await _getPaymentsRef(companyId).doc(paymentId).delete();
  }
}
