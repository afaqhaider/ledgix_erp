class ReportLine {
  final String code;
  final String name;
  final double debit;
  final double credit;
  final double balance;
  final bool isHeader;

  ReportLine({
    required this.code,
    required this.name,
    this.debit = 0,
    this.credit = 0,
    this.balance = 0,
    this.isHeader = false,
  });
}

class TrialBalanceReport {
  final List<ReportLine> lines;
  final double totalDebit;
  final double totalCredit;

  TrialBalanceReport({
    required this.lines,
    required this.totalDebit,
    required this.totalCredit,
  });

  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;
}

class ProfitLossReport {
  final List<ReportSection> sections;
  final double netProfit;

  ProfitLossReport({required this.sections, required this.netProfit});
}

class BalanceSheetReport {
  final List<ReportSection> sections;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;

  BalanceSheetReport({
    required this.sections,
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
