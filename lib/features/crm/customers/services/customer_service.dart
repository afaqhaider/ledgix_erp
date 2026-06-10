import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getCustomersRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customers');
  }

  Stream<List<CustomerModel>> getCustomers(String companyId) {
    return _getCustomersRef(companyId).orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return CustomerModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await _getCustomersRef(customer.companyId).doc().set(customer.toMap());
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _getCustomersRef(customer.companyId).doc(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String companyId, String customerId) async {
    // Check for transactions
    final invoiceSnapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();

    if (invoiceSnapshot.docs.isNotEmpty) {
      throw Exception('Cannot delete customer with existing invoices.');
    }

    final paymentSnapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments')
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();

    if (paymentSnapshot.docs.isNotEmpty) {
      throw Exception('Cannot delete customer with existing payments.');
    }

    await _getCustomersRef(companyId).doc(customerId).delete();
  }
}
