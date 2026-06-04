import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/credit_term_model.dart';
import '../models/payment_term_model.dart';

class TermsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Credit Terms (Customer)
  CollectionReference _getCreditTermsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('creditTerms');
  }

  Stream<List<CreditTermModel>> getCreditTerms(String companyId) {
    return _getCreditTermsRef(companyId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CreditTermModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addCreditTerm(CreditTermModel term) async {
    if (term.isDefault) {
      await _clearDefaultCreditTerm(term.companyId);
    }
    await _getCreditTermsRef(term.companyId).add(term.toMap());
  }

  Future<void> updateCreditTerm(CreditTermModel term) async {
    if (term.isDefault) {
      await _clearDefaultCreditTerm(term.companyId);
    }
    await _getCreditTermsRef(term.companyId).doc(term.id).update(term.toMap());
  }

  Future<void> _clearDefaultCreditTerm(String companyId) async {
    final query = await _getCreditTermsRef(companyId)
        .where('isDefault', isEqualTo: true)
        .get();
    for (var doc in query.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }

  // Payment Terms (Quotation)
  CollectionReference _getPaymentTermsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('paymentTerms');
  }

  Stream<List<PaymentTermModel>> getPaymentTerms(String companyId) {
    return _getPaymentTermsRef(companyId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PaymentTermModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addPaymentTerm(PaymentTermModel term) async {
    if (term.isDefault) {
      await _clearDefaultPaymentTerm(term.companyId);
    }
    await _getPaymentTermsRef(term.companyId).add(term.toMap());
  }

  Future<void> _clearDefaultPaymentTerm(String companyId) async {
    final query = await _getPaymentTermsRef(companyId)
        .where('isDefault', isEqualTo: true)
        .get();
    for (var doc in query.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }
}
