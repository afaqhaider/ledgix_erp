import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';

class ReportLine {
  // ... existing code ...
}

class FinancialReportNode {
  final String id;
  final String code;
  final String name;
  final double openingBalance;
  final double debit;
  final double credit;
  final double balance; // closing balance
  final List<FinancialReportNode> children;
  final bool isGroup;
  final int level;
  final String? type; // 'type', 'category', 'account'
  final AccountCategory? category;

  FinancialReportNode({
    required this.id,
    required this.code,
    required this.name,
    this.openingBalance = 0,
    this.debit = 0,
    this.credit = 0,
    this.balance = 0,
    this.children = const [],
    this.isGroup = false,
    this.level = 0,
    this.type,
    this.category,
  });

  FinancialReportNode copyWith({
    String? id,
    String? code,
    String? name,
    double? openingBalance,
    double? debit,
    double? credit,
    double? balance,
    List<FinancialReportNode>? children,
    bool? isGroup,
    int? level,
    String? type,
    AccountCategory? category,
  }) {
    return FinancialReportNode(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      openingBalance: openingBalance ?? this.openingBalance,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      balance: balance ?? this.balance,
      children: children ?? this.children,
      isGroup: isGroup ?? this.isGroup,
      level: level ?? this.level,
      type: type ?? this.type,
      category: category ?? this.category,
    );
  }
}

class TrialBalanceReport {
  final List<FinancialReportNode> nodes;
  final double totalDebit;
  final double totalCredit;

  TrialBalanceReport({
    required this.nodes,
    required this.totalDebit,
    required this.totalCredit,
  });

  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;
}

class GeneralLedgerReport {
  final List<FinancialReportNode> nodes;
  final double totalOpening;
  final double totalDebit;
  final double totalCredit;
  final double totalClosing;

  GeneralLedgerReport({
    required this.nodes,
    required this.totalOpening,
    required this.totalDebit,
    required this.totalCredit,
    required this.totalClosing,
  });
}

class ProfitLossReport {
  final List<FinancialReportNode> nodes;
  final double totalRevenue;
  final double totalCostOfSales;
  final double totalExpenses;
  final double netProfit;

  ProfitLossReport({
    required this.nodes,
    required this.totalRevenue,
    required this.totalCostOfSales,
    required this.totalExpenses,
    required this.netProfit,
  });
}

class BalanceSheetReport {
  final List<FinancialReportNode> nodes;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;

  BalanceSheetReport({
    required this.nodes,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
  });

  bool get isBalanced =>
      (totalAssets - (totalLiabilities + totalEquity)).abs() < 0.01;
}

class ReportSection {
  final String title;
  final List<ReportLine> lines;
  final double total;

  ReportSection({
    required this.title,
    required this.lines,
    required this.total,
  });
}
