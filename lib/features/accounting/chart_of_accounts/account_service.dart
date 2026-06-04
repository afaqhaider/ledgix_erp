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

  BalanceType getDefaultBalance(AccountType type) {
    switch (type) {
      case AccountType.asset:
      case AccountType.expense:
      case AccountType.costOfSales:
      case AccountType.otherExpense:
        return BalanceType.debit;
      case AccountType.liability:
      case AccountType.equity:
      case AccountType.income:
      case AccountType.otherIncome:
        return BalanceType.credit;
    }
  }

  Future<void> seedDefaultAccounts(String companyId) async {
    final now = DateTime.now();
    final batch = _firestore.batch();
    final colRef = _getAccountsRef(companyId);

    String addAcc({
      required String code,
      required String name,
      required AccountType type,
      required AccountCategory category,
      String? parentId,
      int level = 0,
      bool isGroup = false,
      bool allowPosting = true,
      BalanceType? normalBalance,
      bool isSystemAccount = false,
    }) {
      final ref = colRef.doc();
      final nb = normalBalance ?? getDefaultBalance(type);
      final acc = AccountModel(
        id: ref.id,
        companyId: companyId,
        accountCode: code,
        accountName: name,
        accountType: type,
        accountCategory: category,
        parentAccountId: parentId,
        level: level,
        isGroup: isGroup,
        allowPosting: isGroup ? false : allowPosting,
        normalBalance: nb,
        isSystemAccount: isSystemAccount,
        openingBalanceType: nb,
        openingBalanceDate: now,
        createdAt: now,
      );
      batch.set(ref, acc.toMap());
      return ref.id;
    }

    // 1. ASSETS (1000)
    final assetsId = addAcc(
      code: '1000',
      name: 'Assets',
      type: AccountType.asset,
      category: AccountCategory.currentAsset,
      isGroup: true,
      level: 0,
    );

    // Current Assets (1100)
    final currentAssetsId = addAcc(
      code: '1100',
      name: 'Current Assets',
      type: AccountType.asset,
      category: AccountCategory.currentAsset,
      parentId: assetsId,
      isGroup: true,
      level: 1,
    );

    addAcc(
      code: '1110',
      name: 'Cash on Hand',
      type: AccountType.asset,
      category: AccountCategory.cash,
      parentId: currentAssetsId,
      level: 2,
    );
    addAcc(
      code: '1120',
      name: 'Bank Account',
      type: AccountType.asset,
      category: AccountCategory.bank,
      parentId: currentAssetsId,
      level: 2,
    );
    addAcc(
      code: '1130',
      name: 'Accounts Receivable',
      type: AccountType.asset,
      category: AccountCategory.accountsReceivable,
      parentId: currentAssetsId,
      level: 2,
      isSystemAccount: true,
    );

    // Non-Current Assets (1500)
    final nonCurrentAssetsId = addAcc(
      code: '1500',
      name: 'Non-Current Assets',
      type: AccountType.asset,
      category: AccountCategory.nonCurrentAsset,
      parentId: assetsId,
      isGroup: true,
      level: 1,
    );
    addAcc(
      code: '1510',
      name: 'Furniture & Fixtures',
      type: AccountType.asset,
      category: AccountCategory.nonCurrentAsset,
      parentId: nonCurrentAssetsId,
      level: 2,
    );

    // 2. LIABILITIES (2000)
    final liabilitiesId = addAcc(
      code: '2000',
      name: 'Liabilities',
      type: AccountType.liability,
      category: AccountCategory.currentLiability,
      isGroup: true,
      level: 0,
    );

    final currentLiabilitiesId = addAcc(
      code: '2100',
      name: 'Current Liabilities',
      type: AccountType.liability,
      category: AccountCategory.currentLiability,
      parentId: liabilitiesId,
      isGroup: true,
      level: 1,
    );
    addAcc(
      code: '2110',
      name: 'Accounts Payable',
      type: AccountType.liability,
      category: AccountCategory.accountsPayable,
      parentId: currentLiabilitiesId,
      level: 2,
      isSystemAccount: true,
    );
    addAcc(
      code: '2120',
      name: 'VAT Payable',
      type: AccountType.liability,
      category: AccountCategory.vatPayable,
      parentId: currentLiabilitiesId,
      level: 2,
      isSystemAccount: true,
    );

    // 3. EQUITY (3000)
    final equityId = addAcc(
      code: '3000',
      name: 'Equity',
      type: AccountType.equity,
      category: AccountCategory.ownerEquity,
      isGroup: true,
      level: 0,
    );
    addAcc(
      code: '3100',
      name: 'Owner Equity',
      type: AccountType.equity,
      category: AccountCategory.ownerEquity,
      parentId: equityId,
      level: 1,
    );
    addAcc(
      code: '3200',
      name: 'Retained Earnings',
      type: AccountType.equity,
      category: AccountCategory.retainedEarnings,
      parentId: equityId,
      level: 1,
      isSystemAccount: true,
    );
    addAcc(
      code: '3300',
      name: 'Current Year Earnings',
      type: AccountType.equity,
      category: AccountCategory.currentYearEarnings,
      parentId: equityId,
      level: 1,
      isSystemAccount: true,
    );

    // 4. INCOME (4000)
    final incomeId = addAcc(
      code: '4000',
      name: 'Income',
      type: AccountType.income,
      category: AccountCategory.sales,
      isGroup: true,
      level: 0,
    );
    addAcc(
      code: '4100',
      name: 'Sales Revenue',
      type: AccountType.income,
      category: AccountCategory.sales,
      parentId: incomeId,
      level: 1,
    );
    addAcc(
      code: '4200',
      name: 'Service Income',
      type: AccountType.income,
      category: AccountCategory.serviceIncome,
      parentId: incomeId,
      level: 1,
    );

    // 5. COST OF SALES (5000)
    final cosId = addAcc(
      code: '5000',
      name: 'Cost of Sales',
      type: AccountType.costOfSales,
      category: AccountCategory.cogs,
      isGroup: true,
      level: 0,
    );
    addAcc(
      code: '5100',
      name: 'Cost of Goods Sold',
      type: AccountType.costOfSales,
      category: AccountCategory.cogs,
      parentId: cosId,
      level: 1,
    );

    // 6. EXPENSES (6000)
    final expenseId = addAcc(
      code: '6000',
      name: 'Expenses',
      type: AccountType.expense,
      category: AccountCategory.operatingExpense,
      isGroup: true,
      level: 0,
    );
    addAcc(
      code: '6100',
      name: 'Rent Expense',
      type: AccountType.expense,
      category: AccountCategory.rent,
      parentId: expenseId,
      level: 1,
    );
    addAcc(
      code: '6200',
      name: 'Salaries Expense',
      type: AccountType.expense,
      category: AccountCategory.staffCost,
      parentId: expenseId,
      level: 1,
    );
    addAcc(
      code: '6300',
      name: 'Utilities Expense',
      type: AccountType.expense,
      category: AccountCategory.utilities,
      parentId: expenseId,
      level: 1,
    );

    await batch.commit();
  }
}
