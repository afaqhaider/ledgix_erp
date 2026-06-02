import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';

class CustomerPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments');
  }

  Stream<List<CustomerPaymentModel>> getPayments(String companyId) {
    return _getRef(companyId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CustomerPaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<String> generateNextNumber(String companyId) async {
    final snapshot = await _getRef(companyId)
        .orderBy('paymentNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'CPAY-0001';

    final lastNumberStr = snapshot.docs.first.get('paymentNumber') as String;
    final numberMatch = RegExp(r'\d+').firstMatch(lastNumberStr);
    if (numberMatch != null) {
      final lastNumber = int.parse(numberMatch.group(0)!);
      return 'CPAY-${(lastNumber + 1).toString().padLeft(4, '0')}';
    }
    return 'CPAY-0001';
  }

  Future<void> addPayment(CustomerPaymentModel payment) async {
    await _getRef(payment.companyId).doc().set(payment.toMap());
  }

  Future<void> updatePayment(CustomerPaymentModel payment) async {
    await _getRef(payment.companyId).doc(payment.id).update(payment.toMap());
  }
}
