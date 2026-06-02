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
    return _getAccountsRef(companyId).orderBy('accountCode').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return AccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addAccount(AccountModel account) async {
    await _getAccountsRef(account.companyId).doc().set(account.toMap());
  }

  Future<void> updateAccount(AccountModel account) async {
    await _getAccountsRef(
      account.companyId,
    ).doc(account.id).update(account.toMap());
  }

  Future<void> toggleAccountStatus(
    String companyId,
    String accountId,
    bool isActive,
  ) async {
    await _getAccountsRef(
      companyId,
    ).doc(accountId).update({'isActive': isActive});
  }

  Future<void> seedDefaultAccounts(String companyId) async {
    final now = DateTime.now();
    final defaults = [
      // Assets
      AccountModel(id: '', companyId: companyId, accountCode: '1000', accountName: 'Cash on Hand', accountType: AccountType.asset, openingBalance: 0, openingBalanceType: BalanceType.debit, openingBalanceDate: now, createdAt: now),
      AccountModel(id: '', companyId: companyId, accountCode: '1100', accountName: 'Bank', accountType: AccountType.asset, openingBalance: 0, openingBalanceType: BalanceType.debit, openingBalanceDate: now, createdAt: now),
      AccountModel(id: '', companyId: companyId, accountCode: '1200', accountName: 'Accounts Receivable', accountType: AccountType.asset, openingBalance: 0, openingBalanceType: BalanceType.debit, openingBalanceDate: now, createdAt: now),
      
      // Liabilities
      AccountModel(id: '', companyId: companyId, accountCode: '2000', accountName: 'Accounts Payable', accountType: AccountType.liability, openingBalance: 0, openingBalanceType: BalanceType.credit, openingBalanceDate: now, createdAt: now),
      AccountModel(id: '', companyId: companyId, accountCode: '2100', accountName: 'VAT Payable', accountType: AccountType.liability, openingBalance: 0, openingBalanceType: BalanceType.credit, openingBalanceDate: now, createdAt: now),
      
      // Equity
      AccountModel(id: '', companyId: companyId, accountCode: '3000', accountName: 'Owner Equity', accountType: AccountType.equity, openingBalance: 0, openingBalanceType: BalanceType.credit, openingBalanceDate: now, createdAt: now),
      AccountModel(id: '', companyId: companyId, accountCode: '3100', accountName: 'Retained Earnings', accountType: AccountType.equity, openingBalance: 0, openingBalanceType: BalanceType.credit, openingBalanceDate: now, createdAt: now),
      
      // Income
      AccountModel(id: '', companyId: companyId, accountCode: '4000', accountName: 'Sales Revenue', accountType: AccountType.income, openingBalance: 0, openingBalanceType: BalanceType.credit, openingBalanceDate: now, createdAt: now),
      AccountModel(id: '', companyId: companyId, accountCode: '4100', accountName: 'Other Income', accountType: AccountType.income, openingBalance: 0, openingBalanceType: BalanceType.credit, openingBalanceDate: now, createdAt: now),
      
      // Cost of Sales
      AccountModel(id: '', companyId: companyId, accountCode: '5000', accountName: 'Cost of Goods Sold', accountType: AccountType.costOfSales, openingBalance: 0, openingBalanceType: BalanceType.debit, openingBalanceDate: now, createdAt: now),
      
      // Expenses
      AccountModel(id: '', companyId: companyId, accountCode: '6000', accountName: 'Rent Expense', accountType: AccountType.expense, openingBalance: 0, openingBalanceType: BalanceType.debit, openingBalanceDate: now, createdAt: now),
      AccountModel(id: '', companyId: companyId, accountCode: '6100', accountName: 'Salaries Expense', accountType: AccountType.expense, openingBalance: 0, openingBalanceType: BalanceType.debit, openingBalanceDate: now, createdAt: now),
      AccountModel(id: '', companyId: companyId, accountCode: '6200', accountName: 'Utility Expense', accountType: AccountType.expense, openingBalance: 0, openingBalanceType: BalanceType.debit, openingBalanceDate: now, createdAt: now),
    ];

    final batch = _firestore.batch();
    for (var acc in defaults) {
      final ref = _getAccountsRef(companyId).doc();
      batch.set(ref, acc.toMap()..['id'] = ref.id);
    }
    await batch.commit();
  }
}
