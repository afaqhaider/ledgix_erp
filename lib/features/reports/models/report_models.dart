import '../../accounting/chart_of_accounts/account_model.dart';

class AccountBalance {
  final AccountModel account;
  final double debit;
  final double credit;

  AccountBalance({
    required this.account,
    required this.debit,
    required this.credit,
  });

  double get balance {
    if (account.accountType == AccountType.asset ||
        account.accountType == AccountType.expense ||
        account.accountType == AccountType.costOfSales) {
      return debit - credit;
    } else {
      return credit - debit;
    }
  }
}

class TrialBalanceReport {
  final List<AccountBalance> balances;
  final DateTime asOf;

  TrialBalanceReport({required this.balances, required this.asOf});

  double get totalDebits => balances.fold(0, (sum, b) => sum + b.debit);
  double get totalCredits => balances.fold(0, (sum, b) => sum + b.credit);
}

class ProfitLossReport {
  final List<AccountBalance> income;
  final List<AccountBalance> costOfSales;
  final List<AccountBalance> expenses;
  final DateTime startDate;
  final DateTime endDate;

  ProfitLossReport({
    required this.income,
    required this.costOfSales,
    required this.expenses,
    required this.startDate,
    required this.endDate,
  });

  double get totalIncome => income.fold(0, (sum, b) => sum + b.balance);
  double get totalCostOfSales =>
      costOfSales.fold(0, (sum, b) => sum + b.balance);
  double get grossProfit => totalIncome - totalCostOfSales;
  double get totalExpenses => expenses.fold(0, (sum, b) => sum + b.balance);
  double get netProfit => grossProfit - totalExpenses;
}

class BalanceSheetReport {
  final List<AccountBalance> assets;
  final List<AccountBalance> liabilities;
  final List<AccountBalance> equity;
  final double netProfitPeriod; // Net profit to be added to Equity
  final DateTime asOf;

  BalanceSheetReport({
    required this.assets,
    required this.liabilities,
    required this.equity,
    required this.netProfitPeriod,
    required this.asOf,
  });

  double get totalAssets => assets.fold(0.0, (sum, b) => sum + b.balance);
  double get totalLiabilities =>
      liabilities.fold(0.0, (sum, b) => sum + b.balance);
  double get totalEquity =>
      equity.fold(0.0, (sum, b) => sum + b.balance) + netProfitPeriod;
  double get totalLiabilitiesAndEquity => totalLiabilities + totalEquity;
}
