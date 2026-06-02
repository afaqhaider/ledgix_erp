import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';

class SupplierPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getPaymentsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments');
  }

  Stream<List<SupplierPaymentModel>> getPayments(String companyId) {
    return _getPaymentsRef(companyId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SupplierPaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<String> generateNextPaymentNumber(String companyId) async {
    final snapshot = await _getPaymentsRef(companyId)
        .orderBy('paymentNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'SPAY-0001';
    }

    final lastNumberStr = snapshot.docs.first.get('paymentNumber') as String;
    final numberMatch = RegExp(r'\d+').firstMatch(lastNumberStr);
    if (numberMatch != null) {
      final lastNumber = int.parse(numberMatch.group(0)!);
      final nextNumber = lastNumber + 1;
      return 'SPAY-${nextNumber.toString().padLeft(4, '0')}';
    }

    return 'SPAY-0001';
  }

  Future<void> addPayment(SupplierPaymentModel payment) async {
    await _getPaymentsRef(payment.companyId).doc().set(payment.toMap());
  }
}
