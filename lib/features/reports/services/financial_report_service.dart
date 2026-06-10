import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import '../models/report_models.dart';

class FinancialReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Set<String> _loggedErrors = {};

  void _logMissingField(String reportName, String accountId, String fieldName) {
    final key = '$reportName-$accountId-$fieldName';
    if (!_loggedErrors.contains(key)) {
      debugPrint('FinancialReport ERROR: Missing field "$fieldName" for account $accountId in $reportName');
      _loggedErrors.add(key);
    }
  }

  // --- Main Reports ---

  Future<TrialBalanceReport> getTrialBalance(
    String companyId,
    DateTime asOfDate, {
    bool showGroups = false,
    String? jobId,
  }) async {
    final accounts = await _fetchAccounts(companyId);
    final balances = await _calculateBalances(
      companyId,
      accounts,
      asOfDate,
      jobId: jobId,
    );

    // Initial account nodes
    Map<String, FinancialReportNode> accountNodes = {};
    for (var acc in accounts) {
      double bal = balances[acc.id] ?? 0;
      accountNodes[acc.id] = FinancialReportNode(
        id: acc.id,
        code: acc.accountCode,
        name: acc.accountName,
        debit: bal > 0 ? bal : 0,
        credit: bal < 0 ? bal.abs() : 0,
        balance: bal,
        isGroup: acc.isGroup,
        level: acc.level,
        type: 'account',
        category: acc.accountCategory,
      );
    }

    final rootNodes = _buildStandardHierarchy(
      reportName: 'Trial Balance',
      accounts: accounts,
      accountNodes: accountNodes,
      types: AccountType.values,
      includeZeroBalances: false,
      showGroups: showGroups,
    );

    double totalDebit = 0;
    double totalCredit = 0;
    for (var acc in accounts) {
      if (acc.allowPosting) {
        double bal = balances[acc.id] ?? 0;
        if (bal > 0) {
          totalDebit += bal;
        } else {
          totalCredit += bal.abs();
        }
      }
    }

    return TrialBalanceReport(
      nodes: rootNodes,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
    );
  }

  Future<BalanceSheetReport> getBalanceSheet(
    String companyId,
    DateTime asOfDate, {
    bool showGroups = false,
    String? jobId,
  }) async {
    final accounts = await _fetchAccounts(companyId);
    final balances = await _calculateBalances(
      companyId,
      accounts,
      asOfDate,
      jobId: jobId,
    );

    final bsTypes = [
      AccountType.asset,
      AccountType.liability,
      AccountType.equity,
    ];
    final plTypes = [
      AccountType.income,
      AccountType.costOfSales,
      AccountType.expense,
      AccountType.otherIncome,
      AccountType.otherExpense,
    ];

    double netIncome = 0;
    for (var acc in accounts) {
      if (plTypes.contains(acc.accountType)) {
        netIncome -= (balances[acc.id] ?? 0);
      }
    }

    // Prepare account nodes with proper sign (Assets +, Liab -, Equity -)
    Map<String, FinancialReportNode> accountNodes = {};
    for (var acc in accounts) {
      if (!bsTypes.contains(acc.accountType)) {
        continue;
      }

      double bal = balances[acc.id] ?? 0;
      double displayBal = bal;
      if (acc.normalBalance == BalanceType.credit) {
        displayBal = -bal;
      }

      accountNodes[acc.id] = FinancialReportNode(
        id: acc.id,
        code: acc.accountCode,
        name: acc.accountName,
        balance: displayBal,
        isGroup: acc.isGroup,
        level: acc.level,
        type: 'account',
        category: acc.accountCategory,
      );
    }

    // Add Net Income node if not zero
    if (netIncome != 0) {
      const id = 'net_income_system';
      accountNodes[id] = FinancialReportNode(
        id: id,
        code: '',
        name: 'Current Year Earnings (Net Profit/Loss)',
        balance: netIncome,
        isGroup: false,
        level: 0,
        type: 'account',
      );
      // We'll manually inject this into Retained Earnings or Equity
    }

    var rootNodes = _buildStandardHierarchy(
      reportName: 'Balance Sheet',
      accounts: accounts,
      accountNodes: accountNodes,
      types: bsTypes,
      showGroups: showGroups,
      extraNodes: {
        AccountType.equity: {
          AccountCategory.retainedEarnings: [
            accountNodes['net_income_system'],
          ].whereType<FinancialReportNode>().toList(),
        },
      },
    );

    double totalAssets = 0;
    double totalLiabilities = 0;
    double totalEquity = 0;

    for (var node in rootNodes) {
      if (node.id == AccountType.asset.name) {
        totalAssets = node.balance;
      } else if (node.id == AccountType.liability.name) {
        totalLiabilities = node.balance;
      } else if (node.id == AccountType.equity.name) {
        totalEquity = node.balance;
      }
    }

    return BalanceSheetReport(
      nodes: rootNodes,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      totalEquity: totalEquity,
    );
  }

  Future<ProfitLossReport> getProfitLoss(
    String companyId,
    DateTime? startDate,
    DateTime? endDate, {
    bool showGroups = false,
    String? jobId,
  }) async {
    final now = DateTime.now();
    final effectiveStartDate = startDate ?? DateTime(now.year, now.month, 1);
    final effectiveEndDate = endDate ?? now;

    final accounts = await _fetchAccounts(companyId);
    final movements = await _calculateMovements(
      companyId,
      accounts,
      effectiveStartDate,
      effectiveEndDate,
      jobId: jobId,
    );

    final plTypes = [
      AccountType.income,
      AccountType.costOfSales,
      AccountType.expense,
      AccountType.otherIncome,
      AccountType.otherExpense,
    ];

    Map<String, FinancialReportNode> accountNodes = {};
    for (var acc in accounts) {
      if (!plTypes.contains(acc.accountType)) {
        continue;
      }

      final bal = movements[acc.id] ?? 0.0;
      double displayBal = bal;
      if (acc.normalBalance == BalanceType.credit) {
        displayBal = -bal;
      }

      accountNodes[acc.id] = FinancialReportNode(
        id: acc.id,
        code: acc.accountCode.isEmpty ? '' : acc.accountCode,
        name: acc.accountName.isEmpty ? 'Unnamed Account' : acc.accountName,
        balance: displayBal,
        isGroup: acc.isGroup,
        level: acc.level,
        type: 'account',
        category: acc.accountCategory,
      );
    }

    final rootNodes = _buildStandardHierarchy(
      reportName: 'Profit & Loss',
      accounts: accounts,
      accountNodes: accountNodes,
      types: plTypes,
      showGroups: showGroups,
    );

    double totalRevenue = 0;
    double totalCostOfSales = 0;
    double totalExpenses = 0;

    for (var node in rootNodes) {
      if (node.id == AccountType.income.name ||
          node.id == AccountType.otherIncome.name) {
        totalRevenue += node.balance;
      } else if (node.id == AccountType.costOfSales.name) {
        totalCostOfSales += node.balance;
      } else if (node.id == AccountType.expense.name ||
          node.id == AccountType.otherExpense.name) {
        totalExpenses += node.balance;
      }
    }

    return ProfitLossReport(
      nodes: rootNodes,
      totalRevenue: totalRevenue,
      totalCostOfSales: totalCostOfSales,
      totalExpenses: totalExpenses,
      netProfit: totalRevenue - totalCostOfSales - totalExpenses,
    );
  }

  Future<GeneralLedgerReport> getGeneralLedgerSummary(
    String companyId,
    DateTime startDate,
    DateTime endDate, {
    bool showGroups = false,
    String? jobId,
  }) async {
    final accounts = await _fetchAccounts(companyId);
    final openingBalances = await _calculateBalances(
      companyId,
      accounts,
      startDate.subtract(const Duration(seconds: 1)),
      jobId: jobId,
    );
    final movements = await _calculateDetailedMovements(
      companyId,
      accounts,
      startDate,
      endDate,
      jobId: jobId,
    );

    Map<String, FinancialReportNode> accountNodes = {};
    for (var acc in accounts) {
      double opening = openingBalances[acc.id] ?? 0;
      double dr = movements[acc.id]?['debit'] ?? 0;
      double cr = movements[acc.id]?['credit'] ?? 0;
      double closing = opening + (dr - cr);

      accountNodes[acc.id] = FinancialReportNode(
        id: acc.id,
        code: acc.accountCode,
        name: acc.accountName,
        openingBalance: opening,
        debit: dr,
        credit: cr,
        balance: closing,
        isGroup: acc.isGroup,
        level: acc.level,
        type: 'account',
        category: acc.accountCategory,
      );
    }

    final rootNodes = _buildStandardHierarchy(
      reportName: 'General Ledger Summary',
      accounts: accounts,
      accountNodes: accountNodes,
      types: AccountType.values,
      showGroups: showGroups,
    );

    double grandOpening = 0;
    double grandDebit = 0;
    double grandCredit = 0;
    double grandClosing = 0;

    for (var node in rootNodes) {
      grandOpening += node.openingBalance;
      grandDebit += node.debit;
      grandCredit += node.credit;
      grandClosing += node.balance;
    }

    return GeneralLedgerReport(
      nodes: rootNodes,
      totalOpening: grandOpening,
      totalDebit: grandDebit,
      totalCredit: grandCredit,
      totalClosing: grandClosing,
    );
  }

  Future<StatementOfChangesInEquityReport> getStatementOfChangesInEquity(
    String companyId,
    DateTime startDate,
    DateTime endDate, {
    String? jobId,
  }) async {
    final accounts = await _fetchAccounts(companyId);

    // 1. Get Profit & Loss for the period to get Net Income
    final plReport = await getProfitLoss(
      companyId,
      startDate,
      endDate,
      jobId: jobId,
    );
    final netIncome = plReport.netProfit;

    // 2. Get Opening Balances for all Equity accounts
    final openingBalances = await _calculateBalances(
      companyId,
      accounts,
      startDate.subtract(const Duration(seconds: 1)),
      jobId: jobId,
    );

    // 3. Get Movements for the period
    final movements = await _calculateDetailedMovements(
      companyId,
      accounts,
      startDate,
      endDate,
      jobId: jobId,
    );

    List<EquityChangeNode> nodes = [];
    double totalOpening = 0;
    double totalNetIncomeAlloc = 0;
    double totalOtherChanges = 0;
    double totalClosing = 0;

    // Filter only Equity accounts
    final equityAccounts = accounts
        .where((a) => a.accountType == AccountType.equity && a.allowPosting)
        .toList();

    bool netIncomeAllocated = false;

    for (var acc in equityAccounts) {
      double openingRaw = openingBalances[acc.id] ?? 0.0;
      // Flip for display (Credit is positive for Equity)
      double opening = -openingRaw;

      final move = movements[acc.id] ?? {'debit': 0.0, 'credit': 0.0};
      double dr = move['debit'] ?? 0.0;
      double cr = move['credit'] ?? 0.0;

      // Change = Credit - Debit (Positive = Increase in Equity)
      double change = cr - dr;

      double allocated = 0;
      // Assign Net Income to Retained Earnings
      if (!netIncomeAllocated &&
          (acc.accountCategory == AccountCategory.retainedEarnings ||
              acc.accountName.toLowerCase().contains('retained earnings'))) {
        allocated = netIncome;
        netIncomeAllocated = true;
      }

      double closing = opening + allocated + change;

      // Only show accounts that have any activity or balance
      if (opening.abs() > 0.01 || allocated.abs() > 0.01 || change.abs() > 0.01) {
        nodes.add(EquityChangeNode(
          accountId: acc.id,
          accountName: acc.accountName,
          openingBalance: opening,
          netIncomeAllocated: allocated,
          drawings: 0,
          otherChanges: change,
          closingBalance: closing,
        ));

        totalOpening += opening;
        totalNetIncomeAlloc += allocated;
        totalOtherChanges += change;
        totalClosing += closing;
      }
    }

    // If net income wasn't allocated to an existing account, add a virtual row for it
    if (!netIncomeAllocated && netIncome.abs() > 0.01) {
      nodes.add(EquityChangeNode(
        accountId: 'net_income_virtual',
        accountName: 'Current Year Earnings (Net Income)',
        openingBalance: 0,
        netIncomeAllocated: netIncome,
        drawings: 0,
        otherChanges: 0,
        closingBalance: netIncome,
      ));
      totalNetIncomeAlloc += netIncome;
      totalClosing += netIncome;
    }

    return StatementOfChangesInEquityReport(
      nodes: nodes,
      totalOpeningBalance: totalOpening,
      totalNetIncome: totalNetIncomeAlloc,
      totalOtherChanges: totalOtherChanges,
      totalClosingBalance: totalClosing,
    );
  }

  Future<List<Map<String, dynamic>>> getGeneralLedger(
    String companyId,
    String accountId,
    DateTime startDate,
    DateTime endDate, {
    String? jobId,
  }) async {
    final doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .doc(accountId)
        .get();

    if (!doc.exists) {
      return [];
    }
    final account = AccountModel.fromMap(doc.data()!, doc.id);

    // 1. Calculate Opening Balance
    // If filtering by Job, we don't use the account's global opening balance
    double openingBal = jobId == null ? account.openingBalance : 0.0;
    if (jobId == null && account.openingBalanceType == BalanceType.credit) {
      openingBal = -openingBal;
    }

    final journalsBeforeSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .where('date', isLessThan: Timestamp.fromDate(startDate))
        .get();

    for (var doc in journalsBeforeSnap.docs) {
      final lines = doc.data()['lines'] as List;
      for (var l in lines) {
        if (l['accountId'] == accountId && (jobId == null || l['jobId'] == jobId)) {
          double dr = (l['debit'] as num).toDouble();
          double cr = (l['credit'] as num).toDouble();
          openingBal += (dr - cr);
        }
      }
    }

    List<Map<String, dynamic>> result = [];

    // Add Opening Balance Row
    result.add({
      'date': startDate,
      'description': 'Opening Balance',
      'reference': '',
      'debit': 0.0,
      'credit': 0.0,
      'balance': openingBal,
    });

    // 2. Fetch Movements
    final journalsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: false)
        .get();

    double runningBalance = openingBal;
    for (var doc in journalsSnap.docs) {
      final data = doc.data();
      final lines = data['lines'] as List;
      for (var l in lines) {
        if (l['accountId'] == accountId && (jobId == null || l['jobId'] == jobId)) {
          double dr = (l['debit'] as num).toDouble();
          double cr = (l['credit'] as num).toDouble();
          runningBalance += (dr - cr);

          result.add({
            'date': (data['date'] as Timestamp).toDate(),
            'description': data['description'] ?? '',
            'reference': data['reference'] ?? '',
            'debit': dr,
            'credit': cr,
            'balance': runningBalance,
          });
        }
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getAccountsReceivableDetailed(
    String companyId,
  ) async {
    // 1. Fetch all customers
    final customersSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customers')
        .get();

    // 2. Fetch all posted invoices with balanceDue > 0
    final invoicesSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .where('isPosted', isEqualTo: true)
        .where('balanceDue', isGreaterThan: 0)
        .get();

    Map<String, List<InvoiceModel>> customerInvoices = {};
    for (var doc in invoicesSnap.docs) {
      final inv = InvoiceModel.fromMap(doc.data(), doc.id);
      customerInvoices.putIfAbsent(inv.customerId, () => []).add(inv);
    }

    List<Map<String, dynamic>> result = [];
    for (var doc in customersSnap.docs) {
      final customer = doc.data();
      final customerId = doc.id;
      final invoices = customerInvoices[customerId] ?? [];

      if (invoices.isEmpty) {
        continue;
      }

      double totalInvoiced = invoices.fold(
        0.0,
        (total, inv) => total + inv.totalAmount,
      );
      double totalPaid = invoices.fold(
        0.0,
        (total, inv) => total + inv.amountPaid,
      );
      double outstanding = invoices.fold(
        0.0,
        (total, inv) => total + inv.balanceDue,
      );

      result.add({
        'id': customerId,
        'name': customer['name'] ?? 'Unknown',
        'invoiceCount': invoices.length,
        'totalInvoiced': totalInvoiced,
        'totalPaid': totalPaid,
        'outstanding': outstanding,
      });
    }

    result.sort(
      (a, b) =>
          (b['outstanding'] as double).compareTo(a['outstanding'] as double),
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getAccountsPayableDetailed(
    String companyId,
  ) async {
    final suppliersSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('suppliers')
        .get();

    final billsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierBills')
        .where('isPosted', isEqualTo: true)
        .where('balanceDue', isGreaterThan: 0)
        .get();

    Map<String, List<BillModel>> supplierBills = {};
    for (var doc in billsSnap.docs) {
      final bill = BillModel.fromMap(doc.data(), doc.id);
      supplierBills.putIfAbsent(bill.supplierId, () => []).add(bill);
    }

    List<Map<String, dynamic>> result = [];
    for (var doc in suppliersSnap.docs) {
      final supplier = doc.data();
      final supplierId = doc.id;
      final bills = supplierBills[supplierId] ?? [];

      if (bills.isEmpty) {
        continue;
      }

      double totalBilled = bills.fold(0.0, (total, b) => total + b.totalAmount);
      double totalPaid = bills.fold(0.0, (total, b) => total + b.amountPaid);
      double outstanding = bills.fold(0.0, (total, b) => total + b.balanceDue);

      result.add({
        'id': supplierId,
        'name': supplier['supplierName'] ?? 'Unknown',
        'billCount': bills.length,
        'totalBilled': totalBilled,
        'totalPaid': totalPaid,
        'outstanding': outstanding,
      });
    }

    result.sort(
      (a, b) =>
          (b['outstanding'] as double).compareTo(a['outstanding'] as double),
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getCustomerLedger(
    String companyId,
    String customerId,
  ) async {
    List<Map<String, dynamic>> ledger = [];

    // 1. Invoices
    final invSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .where('customerId', isEqualTo: customerId)
        .where('isPosted', isEqualTo: true)
        .get();

    for (var doc in invSnap.docs) {
      final data = doc.data();
      ledger.add({
        'date': (data['invoiceDate'] as Timestamp).toDate(),
        'type': 'Invoice',
        'number': data['invoiceNumber'],
        'debit': (data['totalAmount'] as num).toDouble(),
        'credit': 0.0,
        'reference': data['reference'] ?? '',
      });
    }

    // 2. Payments
    final paySnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments')
        .where('customerId', isEqualTo: customerId)
        .where('isPosted', isEqualTo: true)
        .get();

    for (var doc in paySnap.docs) {
      final data = doc.data();
      ledger.add({
        'date': (data['paymentDate'] as Timestamp).toDate(),
        'type': 'Payment',
        'number': data['paymentNumber'],
        'debit': 0.0,
        'credit': (data['amount'] as num).toDouble(),
        'reference': data['reference'] ?? '',
      });
    }

    ledger.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    double runningBalance = 0;
    for (var entry in ledger) {
      runningBalance +=
          (entry['debit'] as double) - (entry['credit'] as double);
      entry['balance'] = runningBalance;
    }

    return ledger.reversed.toList();
  }

  Future<List<Map<String, dynamic>>> getSupplierLedger(
    String companyId,
    String supplierId,
  ) async {
    List<Map<String, dynamic>> ledger = [];

    // 1. Bills
    final billSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierBills')
        .where('supplierId', isEqualTo: supplierId)
        .where('isPosted', isEqualTo: true)
        .get();

    for (var doc in billSnap.docs) {
      final data = doc.data();
      ledger.add({
        'date': (data['billDate'] as Timestamp).toDate(),
        'type': 'Bill',
        'number': data['billNumber'],
        'debit': 0.0,
        'credit': (data['totalAmount'] as num).toDouble(),
        'reference': data['reference'] ?? '',
      });
    }

    // 2. Payments
    final paySnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments')
        .where('supplierId', isEqualTo: supplierId)
        .where('isPosted', isEqualTo: true)
        .get();

    for (var doc in paySnap.docs) {
      final data = doc.data();
      ledger.add({
        'date': (data['paymentDate'] as Timestamp).toDate(),
        'type': 'Payment',
        'number': data['paymentNumber'],
        'debit': (data['amount'] as num).toDouble(),
        'credit': 0.0,
        'reference': data['reference'] ?? '',
      });
    }

    ledger.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    double runningBalance = 0;
    for (var entry in ledger) {
      // For suppliers, Credit is the liability increase, Debit is the liability decrease.
      // Net Liability = Credit - Debit
      runningBalance +=
          (entry['credit'] as double) - (entry['debit'] as double);
      entry['balance'] = runningBalance;
    }

    return ledger.reversed.toList();
  }

  // --- Hierarchy Building Logic ---

  List<FinancialReportNode> _buildStandardHierarchy({
    required String reportName,
    required List<AccountModel> accounts,
    required Map<String, FinancialReportNode> accountNodes,
    required List<AccountType> types,
    Map<AccountType, Map<AccountCategory, List<FinancialReportNode>>>?
    extraNodes,
    bool includeZeroBalances = false,
    bool showGroups = false,
  }) {
    // 1. Build recursive account tree first (always needed for balance aggregation)
    Map<String, List<FinancialReportNode>> parentToChildren = {};
    for (var acc in accounts) {
      if (acc.parentAccountId != null) {
        final node = accountNodes[acc.id];
        if (node != null) {
          parentToChildren
              .putIfAbsent(acc.parentAccountId!, () => [])
              .add(node);
        }
      }
    }

    // 2. Resolve account tree and calculate group balances
    Map<String, FinancialReportNode> resolvedNodes = {};

    FinancialReportNode? resolve(String id, int depth) {
      if (resolvedNodes.containsKey(id)) {
        return resolvedNodes[id];
      }

      var node = accountNodes[id];
      if (node == null) return null;

      var children = parentToChildren[id] ?? [];

      List<FinancialReportNode> resolvedChildren = children
          .map((c) => resolve(c.id, depth + 1))
          .whereType<FinancialReportNode>()
          .toList();

      if (resolvedChildren.isNotEmpty) {
        double sumOpening =
            resolvedChildren.fold(0.0, (total, c) => total + c.openingBalance) +
            node.openingBalance;
        double sumDebit =
            resolvedChildren.fold(0.0, (total, c) => total + c.debit) +
            node.debit;
        double sumCredit =
            resolvedChildren.fold(0.0, (total, c) => total + c.credit) +
            node.credit;
        double sumBalance =
            resolvedChildren.fold(0.0, (total, c) => total + c.balance) +
            node.balance;

        node = node.copyWith(
          children: resolvedChildren,
          openingBalance: sumOpening,
          debit: sumDebit,
          credit: sumCredit,
          balance: sumBalance,
          isGroup: true,
          level: depth,
        );
      } else {
        node = node.copyWith(level: depth);
      }

      resolvedNodes[id] = node;
      return node;
    }

    for (var acc in accounts) {
      resolve(acc.id, 2); // Starting from 2 as 0 is Type and 1 is Category
    }

    // 3. Group by Type and Category
    Map<AccountType, Map<AccountCategory, List<FinancialReportNode>>>
    hierarchy = {};

    if (showGroups) {
      // Standard hierarchical view
      for (var acc in accounts) {
        if (!types.contains(acc.accountType)) continue;
        if (acc.parentAccountId != null) continue;

        final node = resolvedNodes[acc.id];
        if (node == null) continue;

        if (!includeZeroBalances &&
            node.openingBalance == 0 &&
            node.debit == 0 &&
            node.credit == 0 &&
            node.balance == 0 &&
            !node.isGroup) {
          continue;
        }

        hierarchy.putIfAbsent(acc.accountType, () => {});
        hierarchy[acc.accountType]!.putIfAbsent(acc.accountCategory, () => []);
        hierarchy[acc.accountType]![acc.accountCategory]!.add(node);
      }
    } else {
      // Simplified view: Main Category -> Sub Category -> Posting Accounts
      for (var acc in accounts) {
        if (!types.contains(acc.accountType)) continue;

        // Condition for visibility in simplified view:
        // 1. It's a posting account (allowPosting is true)
        // 2. AND it has non-zero balance/movement OR includeZeroBalances is true
        if (!acc.allowPosting) continue;

        final node = accountNodes[acc.id];
        if (node == null) continue;

        if (!includeZeroBalances &&
            node.openingBalance == 0 &&
            node.debit == 0 &&
            node.credit == 0 &&
            node.balance == 0) {
          continue;
        }

        // Adjust level to be directly under Category (level 2)
        final flatNode = node.copyWith(level: 2, children: []);

        hierarchy.putIfAbsent(acc.accountType, () => {});
        hierarchy[acc.accountType]!.putIfAbsent(acc.accountCategory, () => []);
        hierarchy[acc.accountType]![acc.accountCategory]!.add(flatNode);
      }
    }

    // 4. Inject extra nodes (like Net Income)
    if (extraNodes != null) {
      extraNodes.forEach((type, catMap) {
        if (!types.contains(type)) {
          return;
        }
        catMap.forEach((cat, nodes) {
          hierarchy.putIfAbsent(type, () => {});
          hierarchy[type]!.putIfAbsent(cat, () => []);
          hierarchy[type]![cat]!.addAll(nodes);
        });
      });
    }

    // 5. Build final root nodes
    List<FinancialReportNode> rootNodes = [];
    for (var type in types) {
      if (!hierarchy.containsKey(type)) {
        continue;
      }

      List<FinancialReportNode> categoryNodes = [];
      for (var cat in AccountCategory.values) {
        if (!hierarchy[type]!.containsKey(cat)) {
          continue;
        }

        final children = hierarchy[type]![cat]!;

        categoryNodes.add(
          FinancialReportNode(
            id: cat.name,
            code: '',
            name: cat.label,
            openingBalance: children.fold(
              0.0,
              (total, n) => total + n.openingBalance,
            ),
            debit: children.fold(0.0, (total, n) => total + n.debit),
            credit: children.fold(0.0, (total, n) => total + n.credit),
            balance: children.fold(0.0, (total, n) => total + n.balance),
            children: children,
            isGroup: true,
            level: 1,
            type: 'category',
          ),
        );
      }

      rootNodes.add(
        FinancialReportNode(
          id: type.name,
          code: '',
          name: type.label,
          openingBalance: categoryNodes.fold(
            0.0,
            (total, n) => total + n.openingBalance,
          ),
          debit: categoryNodes.fold(0.0, (total, n) => total + n.debit),
          credit: categoryNodes.fold(0.0, (total, n) => total + n.credit),
          balance: categoryNodes.fold(0.0, (total, n) => total + n.balance),
          children: categoryNodes,
          isGroup: true,
          level: 0,
          type: 'type',
        ),
      );
    }

    return rootNodes;
  }

  // --- Data Fetching Helpers ---

  Future<List<AccountModel>> _fetchAccounts(String companyId) async {
    final accountsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .where('isActive', isEqualTo: true)
        .get();

    return accountsSnap.docs
        .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Map<String, double>> _calculateBalances(
    String companyId,
    List<AccountModel> accounts,
    DateTime asOfDate, {
    String? jobId,
  }) async {
    Map<String, double> balances = {};
    bool isCurrent = asOfDate.isAfter(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );

    // If filtering by Job, we MUST sum journal entries manually (no shortcut via account.currentBalance)
    if (isCurrent && jobId == null) {
      for (var acc in accounts) {
        double bal = acc.currentBalance;
        if (acc.normalBalance == BalanceType.credit) {
          bal = -bal;
        }
        balances[acc.id] = bal;
      }
    } else {
      for (var acc in accounts) {
        // Only include opening balance if not filtering by specific job
        double bal = jobId == null ? acc.openingBalance : 0.0;
        if (jobId == null && acc.openingBalanceType == BalanceType.credit) {
          bal = -bal;
        }
        balances[acc.id] = bal;
      }

      final journalsSnap = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('journalEntries')
          .where('status', isEqualTo: 'posted')
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(asOfDate))
          .get();

      for (var doc in journalsSnap.docs) {
        final lines = doc.data()['lines'] as List?;
        if (lines == null) continue;
        for (var l in lines) {
          if (l is! Map) continue;
          String? accId = l['accountId'];
          if (accId == null) {
            _logMissingField('Balance Calculation', doc.id, 'accountId');
            continue;
          }
          if (jobId != null && l['jobId'] != jobId) continue;

          double dr = (l['debit'] as num?)?.toDouble() ?? 0.0;
          double cr = (l['credit'] as num?)?.toDouble() ?? 0.0;
          balances[accId] = (balances[accId] ?? 0) + (dr - cr);
        }
      }
    }
    return balances;
  }

  Future<Map<String, double>> _calculateMovements(
    String companyId,
    List<AccountModel> accounts,
    DateTime startDate,
    DateTime endDate, {
    String? jobId,
  }) async {
    Map<String, double> movement = {};
    final journalsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    for (var doc in journalsSnap.docs) {
      final lines = doc.data()['lines'] as List?;
      if (lines == null) continue;
      for (var l in lines) {
        if (l is! Map) continue;
        String? accId = l['accountId'];
        if (accId == null) {
          _logMissingField('Movement Calculation', doc.id, 'accountId');
          continue;
        }
        if (jobId != null && l['jobId'] != jobId) continue;

        double dr = (l['debit'] as num?)?.toDouble() ?? 0.0;
        double cr = (l['credit'] as num?)?.toDouble() ?? 0.0;
        movement[accId] = (movement[accId] ?? 0) + (dr - cr);
      }
    }
    return movement;
  }

  Future<Map<String, Map<String, double>>> _calculateDetailedMovements(
    String companyId,
    List<AccountModel> accounts,
    DateTime startDate,
    DateTime endDate, {
    String? jobId,
  }) async {
    Map<String, Map<String, double>> movements = {};
    final journalsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    for (var doc in journalsSnap.docs) {
      final lines = doc.data()['lines'] as List?;
      if (lines == null) continue;
      for (var l in lines) {
        if (l is! Map) continue;
        String? accId = l['accountId'];
        if (accId == null) {
          _logMissingField('Detailed Movement Calculation', doc.id, 'accountId');
          continue;
        }
        if (jobId != null && l['jobId'] != jobId) continue;

        double dr = (l['debit'] as num?)?.toDouble() ?? 0.0;
        double cr = (l['credit'] as num?)?.toDouble() ?? 0.0;

        movements.putIfAbsent(accId, () => {'debit': 0, 'credit': 0});
        movements[accId]!['debit'] = movements[accId]!['debit']! + dr;
        movements[accId]!['credit'] = movements[accId]!['credit']! + cr;
      }
    }
    return movements;
  }
}
