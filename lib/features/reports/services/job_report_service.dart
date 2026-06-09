import 'package:cloud_firestore/cloud_firestore.dart';
import '../../operations/jobs/models/job_model.dart';
import '../../accounting/chart_of_accounts/account_model.dart';

class JobReportData {
  final JobModel job;
  final double actualRevenue;
  final double actualExpense;

  JobReportData({
    required this.job,
    required this.actualRevenue,
    required this.actualExpense,
  });

  double get actualProfitLoss => actualRevenue - actualExpense;
  double get variance => actualProfitLoss - job.expectedProfitLoss;
  double get profitMargin => actualRevenue > 0 ? (actualProfitLoss / actualRevenue) * 100 : 0.0;
}

class JobReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<JobReportData>> getJobReports(String companyId) async {
    // 1. Get all jobs
    final jobsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('jobs')
        .get();
    
    final jobs = jobsSnap.docs.map((doc) => JobModel.fromMap(doc.data(), doc.id)).toList();

    // 2. Fetch all accounts to determine Revenue vs Expense
    final accountsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .get();
    
    final Map<String, AccountType> accountTypes = {
      for (var doc in accountsSnap.docs) doc.id: AccountType.values.firstWhere(
        (e) => e.name == doc.data()['accountType'], orElse: () => AccountType.unknown
      )
    };

    // 3. Get all journal lines linked to jobs
    final journalSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .get();

    Map<String, double> revenueMap = {}; // jobId -> amount
    Map<String, double> expenseMap = {}; // jobId -> amount

    for (var doc in journalSnap.docs) {
      final lines = (doc.data()['lines'] as List? ?? []);
      for (var lineMap in lines) {
        final jobId = lineMap['jobId'];
        if (jobId != null) {
          final accountId = lineMap['accountId'];
          final type = accountTypes[accountId] ?? AccountType.unknown;
          final debit = (lineMap['debit'] as num?)?.toDouble() ?? 0.0;
          final credit = (lineMap['credit'] as num?)?.toDouble() ?? 0.0;
          
          if (type == AccountType.income || type == AccountType.otherIncome) {
            // Revenue is Net Credit
            revenueMap[jobId] = (revenueMap[jobId] ?? 0) + (credit - debit);
          } else if (type == AccountType.expense || type == AccountType.otherExpense || type == AccountType.costOfSales) {
            // Expense is Net Debit
            expenseMap[jobId] = (expenseMap[jobId] ?? 0) + (debit - credit);
          }
        }
      }
    }

    return jobs.map((job) => JobReportData(
      job: job,
      actualRevenue: revenueMap[job.id] ?? 0.0,
      actualExpense: expenseMap[job.id] ?? 0.0,
    )).toList();
  }

  Future<List<Map<String, dynamic>>> getJobLedger(String companyId, String jobId) async {
    // 1. Fetch all accounts to determine Revenue vs Expense
    final accountsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .get();
    
    final Map<String, String> accountNames = {
      for (var doc in accountsSnap.docs) doc.id: doc.data()['name'] ?? 'Unknown'
    };

    final Map<String, AccountType> accountTypes = {
      for (var doc in accountsSnap.docs) doc.id: AccountType.values.firstWhere(
        (e) => e.name == doc.data()['accountType'], orElse: () => AccountType.unknown
      )
    };

    // 2. Get all journal entries (ideally we'd have a better index, but following existing pattern)
    final journalSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .get();

    List<Map<String, dynamic>> ledgerLines = [];
    double runningBalance = 0.0;

    for (var doc in journalSnap.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final reference = data['reference'] ?? '';
      final description = data['description'] ?? '';
      final lines = (data['lines'] as List? ?? []);

      for (var lineMap in lines) {
        if (lineMap['jobId'] == jobId) {
          final accountId = lineMap['accountId'];
          final type = accountTypes[accountId] ?? AccountType.unknown;
          final debit = (lineMap['debit'] as num?)?.toDouble() ?? 0.0;
          final credit = (lineMap['credit'] as num?)?.toDouble() ?? 0.0;
          
          double impact = 0.0;
          if (type == AccountType.income || type == AccountType.otherIncome) {
            impact = credit - debit;
          } else if (type == AccountType.expense || type == AccountType.otherExpense || type == AccountType.costOfSales) {
            impact = -(debit - credit); // Expense reduces profit
          }

          runningBalance += impact;

          ledgerLines.add({
            'date': date,
            'description': description,
            'reference': reference,
            'accountName': accountNames[accountId] ?? 'Unknown',
            'debit': debit,
            'credit': credit,
            'impact': impact,
            'runningBalance': runningBalance,
          });
        }
      }
    }

    // Sort by date
    ledgerLines.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    // Recalculate running balance after sort
    double rb = 0.0;
    for (var line in ledgerLines) {
      rb += line['impact'];
      line['runningBalance'] = rb;
    }

    return ledgerLines;
  }
}
