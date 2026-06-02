import 'package:cloud_firestore/cloud_firestore.dart';
import '../../accounting/chart_of_accounts/account_model.dart';
import '../../accounting/journal/models/journal_entry_model.dart';
import '../models/report_models.dart';

class ReportingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<TrialBalanceReport> getTrialBalance(String companyId, DateTime asOf) async {
    // 1. Fetch all accounts
    final accountsSnap = await _firestore
        .collection('accounts')
        .where('companyId', isEqualTo: companyId)
        .get();
    
    final accounts = accountsSnap.docs
        .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
        .toList();

    // 2. Fetch all posted journal entries up to 'asOf'
    final entriesSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(asOf))
        .where('status', isEqualTo: JournalStatus.posted.name)
        .get();

    final Map<String, double> debits = {};
    final Map<String, double> credits = {};

    for (var doc in entriesSnap.docs) {
      final entry = JournalEntryModel.fromMap(doc.data(), doc.id);
      for (var line in entry.lines) {
        debits[line.accountId] = (debits[line.accountId] ?? 0.0) + line.debit;
        credits[line.accountId] = (credits[line.accountId] ?? 0.0) + line.credit;
      }
    }

    final balances = accounts.map((account) {
      // Include opening balances
      double openingDebit = 0;
      double openingCredit = 0;
      if (account.openingBalanceType == BalanceType.debit) {
        openingDebit = account.openingBalance;
      } else {
        openingCredit = account.openingBalance;
      }

      return AccountBalance(
        account: account,
        debit: (debits[account.id] ?? 0.0) + openingDebit,
        credit: (credits[account.id] ?? 0.0) + openingCredit,
      );
    }).toList();

    return TrialBalanceReport(balances: balances, asOf: asOf);
  }

  Future<ProfitLossReport> getProfitLoss(
    String companyId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    final trialBalance = await getTrialBalance(companyId, endDate);
    
    // Filter by date range for P&L accounts (Income, Expense, COGS)
    // Actually, Trial Balance gives cumulative, but P&L is for a period.
    // So we need to subtract the balances at 'startDate'.
    
    final startTrialBalance = await getTrialBalance(companyId, startDate.subtract(const Duration(days: 1)));

    final income = _calculatePeriodBalances(trialBalance, startTrialBalance, AccountType.income);
    final costOfSales = _calculatePeriodBalances(trialBalance, startTrialBalance, AccountType.costOfSales);
    final expenses = _calculatePeriodBalances(trialBalance, startTrialBalance, AccountType.expense);

    return ProfitLossReport(
      income: income,
      costOfSales: costOfSales,
      expenses: expenses,
      startDate: startDate,
      endDate: endDate,
    );
  }

  List<AccountBalance> _calculatePeriodBalances(
    TrialBalanceReport end, 
    TrialBalanceReport start, 
    AccountType type
  ) {
    return end.balances
        .where((b) => b.account.accountType == type)
        .map((endBal) {
          final startBal = start.balances.firstWhere(
            (s) => s.account.id == endBal.account.id,
            orElse: () => AccountBalance(account: endBal.account, debit: 0, credit: 0)
          );
          return AccountBalance(
            account: endBal.account,
            debit: endBal.debit - startBal.debit,
            credit: endBal.credit - startBal.credit,
          );
        })
        .where((b) => b.debit != 0 || b.credit != 0)
        .toList();
  }

  Future<BalanceSheetReport> getBalanceSheet(String companyId, DateTime asOf) async {
    final trialBalance = await getTrialBalance(companyId, asOf);

    final assets = trialBalance.balances
        .where((b) => b.account.accountType == AccountType.asset)
        .toList();
    final liabilities = trialBalance.balances
        .where((b) => b.account.accountType == AccountType.liability)
        .toList();
    final equity = trialBalance.balances
        .where((b) => b.account.accountType == AccountType.equity)
        .toList();

    // Calculate Net Profit for the period (all Income and Expenses up to asOf)
    final income = trialBalance.balances
        .where((b) => b.account.accountType == AccountType.income)
        .fold(0.0, (total, b) => total + b.balance);
    final costOfSales = trialBalance.balances
        .where((b) => b.account.accountType == AccountType.costOfSales)
        .fold(0.0, (total, b) => total + b.balance);
    final expenses = trialBalance.balances
        .where((b) => b.account.accountType == AccountType.expense)
        .fold(0.0, (total, b) => total + b.balance);
    
    final netProfit = income - costOfSales - expenses;

    return BalanceSheetReport(
      assets: assets,
      liabilities: liabilities,
      equity: equity,
      netProfitPeriod: netProfit,
      asOf: asOf,
    );
  }
}
