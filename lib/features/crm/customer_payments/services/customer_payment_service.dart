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
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(
      payment.companyId,
      payment.paymentDate,
    )) {
      throw Exception('Accounting period for this date is locked.');
    }

    await _firestore.runTransaction((transaction) async {
      // 1. ALL READS FIRST (WEB REQUIREMENT)
      
      // Get settings snapshot for number generation
      final settingsRef = _firestore.collection('settings').doc(payment.companyId);
      final settingsSnap = await transaction.get(settingsRef);
      
      // Get all invoice snapshots
      final List<DocumentSnapshot> invoiceSnaps = [];
      final List<String> invoiceIds = [];
      
      if (payment.allocations.isNotEmpty) {
        for (var allocation in payment.allocations) {
          invoiceIds.add(allocation.invoiceId);
        }
      } else if (payment.invoiceId != null) {
        invoiceIds.add(payment.invoiceId!);
      }

      for (var id in invoiceIds) {
        final invRef = _firestore
            .collection('companies')
            .doc(payment.companyId)
            .collection('salesInvoices')
            .doc(id);
        invoiceSnaps.add(await transaction.get(invRef));
      }

      // 2. ALL WRITES AFTER
      
      // Generate final number and increment
      final finalNumber = await _settingsService.getNextDocumentNumberAndIncrement(
        payment.companyId,
        'receipt',
        transaction: transaction,
      );

      final payRef = _getRef(payment.companyId).doc();
      final paymentToSave = payment.copyWith(
        id: payRef.id,
        paymentNumber: finalNumber,
      );

      transaction.set(payRef, paymentToSave.toMap());

      // Update invoices
      for (var i = 0; i < invoiceIds.length; i++) {
        final invSnap = invoiceSnaps[i];
        if (invSnap.exists) {
          final data = invSnap.data() as Map<String, dynamic>;
          final currentPaid = (data['amountPaid'] as num?)?.toDouble() ?? 0.0;
          final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

          double allocationAmount = payment.amount;
          if (payment.allocations.isNotEmpty) {
            allocationAmount = payment.allocations[i].amount;
          }

          final newPaid = currentPaid + allocationAmount;
          final newBalance = totalAmount - newPaid;

          String status = 'partiallyPaid';
          if (newBalance <= 0) {
            status = 'paid';
          }

          transaction.update(invSnap.reference, {
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

    final payment = CustomerPaymentModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
    if (payment.isPosted) {
      throw Exception(
        'Cannot delete a posted payment. Reverse the entry via Journal if needed.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      // 1. ALL READS FIRST
      final List<DocumentSnapshot> invoiceSnaps = [];
      final List<String> invoiceIds = [];

      if (payment.allocations.isNotEmpty) {
        for (var allocation in payment.allocations) {
          invoiceIds.add(allocation.invoiceId);
        }
      } else if (payment.invoiceId != null) {
        invoiceIds.add(payment.invoiceId!);
      }

      for (var id in invoiceIds) {
        final invRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .doc(id);
        invoiceSnaps.add(await transaction.get(invRef));
      }

      // 2. ALL WRITES AFTER
      
      // Reverse allocations
      for (var i = 0; i < invoiceIds.length; i++) {
        final invSnap = invoiceSnaps[i];
        if (invSnap.exists) {
          final data = invSnap.data() as Map<String, dynamic>;
          final currentPaid = (data['amountPaid'] as num?)?.toDouble() ?? 0.0;
          final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

          double allocationAmount = payment.amount;
          if (payment.allocations.isNotEmpty) {
            allocationAmount = payment.allocations[i].amount;
          }

          final newPaid = currentPaid - allocationAmount;
          final newBalance = totalAmount - newPaid;

          String status = 'sent';
          if (newPaid > 0 && newBalance > 0) {
            status = 'partiallyPaid';
          } else if (newBalance <= 0) {
            status = 'paid';
          }

          transaction.update(invSnap.reference, {
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
