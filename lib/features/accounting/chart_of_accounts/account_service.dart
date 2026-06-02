import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';

class AccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getAccountsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts');
  }

  Stream<List<AccountModel>> getAccounts(String companyId) {
    return _getAccountsRef(companyId)
        .orderBy('accountCode')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addAccount(AccountModel account) async {
    await _getAccountsRef(account.companyId).doc().set(account.toMap());
  }

  Future<void> updateAccount(AccountModel account) async {
    await _getAccountsRef(account.companyId).doc(account.id).update(account.toMap());
  }

  Future<void> toggleAccountStatus(String companyId, String accountId, bool isActive) async {
    await _getAccountsRef(companyId).doc(accountId).update({'isActive': isActive});
  }
}
