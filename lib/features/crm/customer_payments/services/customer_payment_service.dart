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
    return await _settingsService.generateNextDocumentNumber(companyId, 'customerPayment');
  }

  Future<void> addPayment(CustomerPaymentModel payment) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(
      payment.companyId,
      payment.paymentDate,
    )) {
      throw Exception('Accounting period for this date is locked.');
    }

    await _firestore.runTransaction((transaction) async {
      final payRef = _getRef(payment.companyId).doc();
      transaction.set(payRef, payment.toMap()..['id'] = payRef.id);

      // Update invoice if linked
      if (payment.invoiceId != null) {
        final invRef = _firestore
            .collection('companies')
            .doc(payment.companyId)
            .collection('salesInvoices')
            .doc(payment.invoiceId);

        final invDoc = await transaction.get(invRef);
        if (invDoc.exists) {
          final currentPaid = (invDoc.data()?['amountPaid'] as num?)?.toDouble() ?? 0.0;
          final totalAmount = (invDoc.data()?['totalAmount'] as num?)?.toDouble() ?? 0.0;
          
          final newPaid = currentPaid + payment.amount;
          final newBalance = totalAmount - newPaid;
          
          String status = 'partiallyPaid';
          if (newBalance <= 0) {
            status = 'paid';
          }

          transaction.update(invRef, {
            'amountPaid': newPaid,
            'balanceDue': newBalance,
            'status': status,
          });
        }
      }
    });
  }

  Future<void> updatePayment(CustomerPaymentModel payment) async {
    if (payment.isPosted) throw Exception('Cannot update a posted payment.');
    await _getRef(payment.companyId).doc(payment.id).update(payment.toMap());
  }

  Future<void> deletePayment(String companyId, String paymentId) async {
    final doc = await _getRef(companyId).doc(paymentId).get();
    if (!doc.exists) return;
    
    final payment = CustomerPaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    if (payment.isPosted) {
      throw Exception('Cannot delete a posted payment. Reverse the entry via Journal if needed.');
    }

    await _firestore.runTransaction((transaction) async {
      // If linked to invoice, reverse the amounts
      if (payment.invoiceId != null) {
        final invRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .doc(payment.invoiceId!);
        
        final invDoc = await transaction.get(invRef);
        if (invDoc.exists) {
          final currentPaid = (invDoc.data()?['amountPaid'] as num?)?.toDouble() ?? 0.0;
          final totalAmount = (invDoc.data()?['totalAmount'] as num?)?.toDouble() ?? 0.0;
          
          final newPaid = currentPaid - payment.amount;
          final newBalance = totalAmount - newPaid;
          
          String status = 'sent';
          if (newPaid > 0 && newBalance > 0) {
            status = 'partiallyPaid';
          } else if (newBalance <= 0) {
            status = 'paid';
          }

          transaction.update(invRef, {
            'amountPaid': newPaid,
            'balanceDue': newBalance,
            'status': status,
          });
        }
      }
      transaction.delete(_getRef(companyId).doc(paymentId));
    });
  }
}
