import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import '../models/report_models.dart';

class FinancialReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<TrialBalanceReport> getTrialBalance(
    String companyId,
    DateTime asOfDate,
  ) async {
    // 1. Fetch all accounts
    final accountsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .where('isActive', isEqualTo: true)
        .get();

    final accounts = accountsSnap.docs
        .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
        .toList();

    Map<String, double> accountBalances = {};
    
    // Check if we can use currentBalance (if asOfDate is today or future)
    bool useCurrentBalance = asOfDate.isAfter(DateTime.now().subtract(const Duration(minutes: 5)));

    if (useCurrentBalance) {
      for (var acc in accounts) {
        double balance = acc.currentBalance;
        // In currentBalance, we store it as a positive number relative to its normal balance
        // Trial Balance usually needs Debit as positive and Credit as negative for internal calculation
        if (acc.accountType == AccountType.liability || 
            acc.accountType == AccountType.equity || 
            acc.accountType == AccountType.income ||
            acc.accountType == AccountType.otherIncome) {
          balance = -balance;
        }
        accountBalances[acc.id] = balance;
      }
    } else {
      // Fetch journal entries up to asOfDate and calculate back (or from start)
      // For now, keep the "scan from start" logic for past dates
      final journalsSnap = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('journalEntries')
          .where('status', isEqualTo: 'posted')
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(asOfDate))
          .get();

      final journals = journalsSnap.docs
          .map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id))
          .toList();

      for (var acc in accounts) {
        double opening = acc.openingBalance;
        if (acc.openingBalanceType == BalanceType.credit) {
          opening = -opening;
        }
        accountBalances[acc.id] = opening;
      }

      for (var j in journals) {
        for (var line in j.lines) {
          double current = accountBalances[line.accountId] ?? 0;
          accountBalances[line.accountId] = current + (line.debit - line.credit);
        }
      }
    }

    List<ReportLine> lines = [];
    double totalDebit = 0;
    double totalCredit = 0;

    for (var acc in accounts) {
      double balance = accountBalances[acc.id] ?? 0;
      double debit = 0;
      double credit = 0;

      if (balance > 0) {
        debit = balance;
        totalDebit += debit;
      } else if (balance < 0) {
        credit = balance.abs();
        totalCredit += credit;
      }

      lines.add(
        ReportLine(
          code: acc.accountCode,
          name: acc.accountName,
          debit: debit,
          credit: credit,
          balance: balance,
        ),
      );
    }

    lines.sort((a, b) => a.code.compareTo(b.code));

    return TrialBalanceReport(
      lines: lines,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
    );
  }

  Future<ProfitLossReport> getProfitLoss(
    String companyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final accountsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .where('isActive', isEqualTo: true)
        .get();

    final allAccounts = accountsSnap.docs
        .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
        .toList();

    final journalsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final journals = journalsSnap.docs
        .map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id))
        .toList();

    Map<String, double> movement = {};
    for (var j in journals) {
      for (var line in j.lines) {
        movement[line.accountId] = (movement[line.accountId] ?? 0) + (line.debit - line.credit);
      }
    }

    ReportSection buildSection(String title, List<AccountType> types) {
      List<ReportLine> lines = [];
      double total = 0;

      final sectionAccounts = allAccounts.where((a) => types.contains(a.accountType)).toList();
      for (var acc in sectionAccounts) {
        double bal = movement[acc.id] ?? 0;
        if (bal != 0) {
          double displayBal = bal;
          if (acc.accountType == AccountType.income || acc.accountType == AccountType.otherIncome) {
            displayBal = -bal;
          }
          lines.add(ReportLine(code: acc.accountCode, name: acc.accountName, balance: displayBal));
          total += displayBal;
        }
      }
      return ReportSection(title: title, lines: lines, total: total);
    }

    final revenue = buildSection('Revenue', [AccountType.income]);
    final cos = buildSection('Cost of Sales', [AccountType.costOfSales]);
    final expenses = buildSection('Operating Expenses', [AccountType.expense]);
    final otherIncome = buildSection('Other Income', [AccountType.otherIncome]);
    final otherExpenses = buildSection('Other Expenses', [AccountType.otherExpense]);

    double netProfit = revenue.total - cos.total - expenses.total + otherIncome.total - otherExpenses.total;

    return ProfitLossReport(
      sections: [revenue, cos, expenses, otherIncome, otherExpenses],
      netProfit: netProfit,
    );
  }

  Future<BalanceSheetReport> getBalanceSheet(
    String companyId,
    DateTime asOfDate,
  ) async {
    final tb = await getTrialBalance(companyId, asOfDate);

    final accountsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .where('isActive', isEqualTo: true)
        .get();

    final allAccounts = accountsSnap.docs
        .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
        .toList();

    ReportSection buildSection(String title, List<AccountType> types) {
      List<ReportLine> lines = [];
      double total = 0;

      for (var acc in allAccounts) {
        if (types.contains(acc.accountType)) {
          final tbLine = tb.lines.firstWhere(
            (l) => l.code == acc.accountCode,
            orElse: () => ReportLine(code: '', name: ''),
          );
          if (tbLine.balance != 0) {
            double displayBal = tbLine.balance;
            if (acc.accountType == AccountType.liability || acc.accountType == AccountType.equity) {
              displayBal = -tbLine.balance;
            }
            lines.add(ReportLine(code: acc.accountCode, name: acc.accountName, balance: displayBal));
            total += displayBal;
          }
        }
      }
      return ReportSection(title: title, lines: lines, total: total);
    }

    final assets = buildSection('Assets', [AccountType.asset]);
    final liabilities = buildSection('Liabilities', [AccountType.liability]);
    final equitySection = buildSection('Equity', [AccountType.equity]);

    double currentEarnings = 0;
    for (var acc in allAccounts) {
      if ([AccountType.income, AccountType.expense, AccountType.costOfSales, AccountType.otherIncome, AccountType.otherExpense].contains(acc.accountType)) {
        final tbLine = tb.lines.firstWhere(
          (l) => l.code == acc.accountCode,
          orElse: () => ReportLine(code: '', name: ''),
        );
        currentEarnings -= tbLine.balance;
      }
    }

    final finalEquityLines = [...equitySection.lines];
    if (currentEarnings != 0) {
      finalEquityLines.add(ReportLine(code: 'EARN', name: 'Current Year Earnings', balance: currentEarnings));
    }

    final totalEquity = equitySection.total + currentEarnings;

    return BalanceSheetReport(
      sections: [
        assets,
        liabilities,
        ReportSection(title: 'Equity', lines: finalEquityLines, total: totalEquity),
      ],
      totalAssets: assets.total,
      totalLiabilities: liabilities.total,
      totalEquity: totalEquity,
    );
  }

  Future<List<Map<String, dynamic>>> getGeneralLedger(
    String companyId,
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final accountDoc = await _firestore.collection('companies').doc(companyId).collection('chartOfAccounts').doc(accountId).get();
    if (!accountDoc.exists) return [];
    final account = AccountModel.fromMap(accountDoc.data()!, accountDoc.id);

    // Opening Balance at startDate
    double openingBalance = account.openingBalance;
    if (account.openingBalanceType == BalanceType.credit) {
      openingBalance = -openingBalance;
    }

    // Instead of scanning all journals from beginning of time, 
    // we can use currentBalance and subtract journals between startDate and today if startDate is recent.
    // Or for now, keep the scan from beginning for GL drill-down as it's more robust.
    
    final beforeJournalsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .where('date', isLessThan: Timestamp.fromDate(startDate))
        .get();

    for (var doc in beforeJournalsSnap.docs) {
      final lines = doc.data()['lines'] as List;
      for (var l in lines) {
        if (l['accountId'] == accountId) {
          openingBalance += ((l['debit'] as num).toDouble() - (l['credit'] as num).toDouble());
        }
      }
    }

    final journalsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    List<Map<String, dynamic>> result = [];
    double runningBalance = openingBalance;

    result.add({
      'date': startDate,
      'description': 'Opening Balance',
      'reference': '',
      'debit': 0.0,
      'credit': 0.0,
      'balance': runningBalance,
    });

    for (var doc in journalsSnap.docs) {
      final j = JournalEntryModel.fromMap(doc.data(), doc.id);
      for (var line in j.lines) {
        if (line.accountId == accountId) {
          runningBalance += (line.debit - line.credit);
          result.add({
            'date': j.date,
            'description': j.description + (line.memo != null && line.memo!.isNotEmpty ? ' - ${line.memo}' : ''),
            'reference': j.reference,
            'debit': line.debit,
            'credit': line.credit,
            'balance': runningBalance,
          });
        }
      }
    }

    return result;
  }
}
