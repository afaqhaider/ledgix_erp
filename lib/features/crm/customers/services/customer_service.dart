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
    return _getCustomersRef(companyId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await _getCustomersRef(customer.companyId).doc().set(customer.toMap());
  }
}
