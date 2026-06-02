import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';

class BankAccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('bankAccounts');
  }

  Stream<List<BankAccountModel>> getBankAccounts(String companyId) {
    return _getRef(companyId).orderBy('accountName').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return BankAccountModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> addBankAccount(BankAccountModel account) async {
    await _getRef(account.companyId).doc().set(account.toMap());
  }

  Future<void> updateBankAccount(BankAccountModel account) async {
    await _getRef(account.companyId).doc(account.id).update(account.toMap());
  }
}
