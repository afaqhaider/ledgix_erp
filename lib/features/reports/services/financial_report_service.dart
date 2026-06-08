import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import '../models/report_models.dart';

class FinancialReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Main Reports ---

  Future<TrialBalanceReport> getTrialBalance(String companyId, DateTime asOfDate) async {
    final accounts = await _fetchAccounts(companyId);
    final balances = await _calculateBalances(companyId, accounts, asOfDate);

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
      accounts: accounts,
      accountNodes: accountNodes,
      types: AccountType.values,
      includeZeroBalances: false,
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

  Future<BalanceSheetReport> getBalanceSheet(String companyId, DateTime asOfDate) async {
    final accounts = await _fetchAccounts(companyId);
    final balances = await _calculateBalances(companyId, accounts, asOfDate);

    final bsTypes = [AccountType.asset, AccountType.liability, AccountType.equity];
    final plTypes = [AccountType.income, AccountType.costOfSales, AccountType.expense, AccountType.otherIncome, AccountType.otherExpense];

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
      accounts: accounts,
      accountNodes: accountNodes,
      types: bsTypes,
      extraNodes: {
        AccountType.equity: {
          AccountCategory.retainedEarnings: [accountNodes['net_income_system']].whereType<FinancialReportNode>().toList(),
        }
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

  Future<ProfitLossReport> getProfitLoss(String companyId, DateTime startDate, DateTime endDate) async {
    final accounts = await _fetchAccounts(companyId);
    final movements = await _calculateMovements(companyId, accounts, startDate, endDate);

    final plTypes = [AccountType.income, AccountType.costOfSales, AccountType.expense, AccountType.otherIncome, AccountType.otherExpense];

    Map<String, FinancialReportNode> accountNodes = {};
    for (var acc in accounts) {
      if (!plTypes.contains(acc.accountType)) {
        continue;
      }

      double bal = movements[acc.id] ?? 0;
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

    final rootNodes = _buildStandardHierarchy(
      accounts: accounts,
      accountNodes: accountNodes,
      types: plTypes,
    );

    double totalRevenue = 0;
    double totalCostOfSales = 0;
    double totalExpenses = 0;

    for (var node in rootNodes) {
      if (node.id == AccountType.income.name || node.id == AccountType.otherIncome.name) {
        totalRevenue += node.balance;
      } else if (node.id == AccountType.costOfSales.name) {
        totalCostOfSales += node.balance;
      } else if (node.id == AccountType.expense.name || node.id == AccountType.otherExpense.name) {
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

  Future<GeneralLedgerReport> getGeneralLedgerSummary(String companyId, DateTime startDate, DateTime endDate) async {
    final accounts = await _fetchAccounts(companyId);
    final openingBalances = await _calculateBalances(companyId, accounts, startDate.subtract(const Duration(seconds: 1)));
    final movements = await _calculateDetailedMovements(companyId, accounts, startDate, endDate);

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
      accounts: accounts,
      accountNodes: accountNodes,
      types: AccountType.values,
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

  Future<List<Map<String, dynamic>>> getGeneralLedger(
    String companyId,
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
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
    double openingBal = account.openingBalance;
    if (account.openingBalanceType == BalanceType.credit) {
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
        if (l['accountId'] == accountId) {
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
        if (l['accountId'] == accountId) {
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

  Future<List<Map<String, dynamic>>> getAccountsReceivableDetailed(String companyId) async {
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

      double totalInvoiced = invoices.fold(0.0, (total, inv) => total + inv.totalAmount);
      double totalPaid = invoices.fold(0.0, (total, inv) => total + inv.amountPaid);
      double outstanding = invoices.fold(0.0, (total, inv) => total + inv.balanceDue);

      result.add({
        'id': customerId,
        'name': customer['name'] ?? 'Unknown',
        'invoiceCount': invoices.length,
        'totalInvoiced': totalInvoiced,
        'totalPaid': totalPaid,
        'outstanding': outstanding,
      });
    }

    result.sort((a, b) => (b['outstanding'] as double).compareTo(a['outstanding'] as double));
    return result;
  }

  Future<List<Map<String, dynamic>>> getAccountsPayableDetailed(String companyId) async {
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

    result.sort((a, b) => (b['outstanding'] as double).compareTo(a['outstanding'] as double));
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

    ledger.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    double runningBalance = 0;
    for (var entry in ledger) {
      runningBalance += (entry['debit'] as double) - (entry['credit'] as double);
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

    ledger.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    double runningBalance = 0;
    for (var entry in ledger) {
      // For suppliers, Credit is the liability increase, Debit is the liability decrease.
      // Net Liability = Credit - Debit
      runningBalance += (entry['credit'] as double) - (entry['debit'] as double);
      entry['balance'] = runningBalance;
    }

    return ledger.reversed.toList();
  }

  // --- Hierarchy Building Logic ---

  List<FinancialReportNode> _buildStandardHierarchy({
    required List<AccountModel> accounts,
    required Map<String, FinancialReportNode> accountNodes,
    required List<AccountType> types,
    Map<AccountType, Map<AccountCategory, List<FinancialReportNode>>>? extraNodes,
    bool includeZeroBalances = false,
  }) {
    // 1. Build recursive account tree first
    Map<String, List<FinancialReportNode>> parentToChildren = {};
    for (var acc in accounts) {
      if (acc.parentAccountId != null) {
        parentToChildren.putIfAbsent(acc.parentAccountId!, () => []).add(accountNodes[acc.id]!);
      }
    }

    // 2. Resolve account tree and calculate group balances
    Map<String, FinancialReportNode> resolvedNodes = {};
    
    FinancialReportNode resolve(String id, int depth) {
      if (resolvedNodes.containsKey(id)) {
        return resolvedNodes[id]!;
      }
      
      var node = accountNodes[id]!;
      var children = parentToChildren[id] ?? [];
      
      List<FinancialReportNode> resolvedChildren = children.map((c) => resolve(c.id, depth + 1)).toList();
      
      if (resolvedChildren.isNotEmpty) {
        double sumOpening = resolvedChildren.fold(0.0, (total, c) => total + c.openingBalance) + node.openingBalance;
        double sumDebit = resolvedChildren.fold(0.0, (total, c) => total + c.debit) + node.debit;
        double sumCredit = resolvedChildren.fold(0.0, (total, c) => total + c.credit) + node.credit;
        double sumBalance = resolvedChildren.fold(0.0, (total, c) => total + c.balance) + node.balance;

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
    Map<AccountType, Map<AccountCategory, List<FinancialReportNode>>> hierarchy = {};

    for (var acc in accounts) {
      if (!types.contains(acc.accountType)) {
        continue;
      }
      if (acc.parentAccountId != null) {
        continue; // Only top-level accounts/groups under Category
      }

      final node = resolvedNodes[acc.id]!;
      
      // Filter out zero balance nodes if requested
      if (!includeZeroBalances && node.openingBalance == 0 && node.debit == 0 && node.credit == 0 && node.balance == 0 && !node.isGroup) {
        continue;
      }

      hierarchy.putIfAbsent(acc.accountType, () => {});
      hierarchy[acc.accountType]!.putIfAbsent(acc.accountCategory, () => []);
      hierarchy[acc.accountType]![acc.accountCategory]!.add(node);
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
        
        categoryNodes.add(FinancialReportNode(
          id: cat.name,
          code: '',
          name: cat.label,
          openingBalance: children.fold(0.0, (total, n) => total + n.openingBalance),
          debit: children.fold(0.0, (total, n) => total + n.debit),
          credit: children.fold(0.0, (total, n) => total + n.credit),
          balance: children.fold(0.0, (total, n) => total + n.balance),
          children: children,
          isGroup: true,
          level: 1,
          type: 'category',
        ));
      }

      rootNodes.add(FinancialReportNode(
        id: type.name,
        code: '',
        name: type.label,
        openingBalance: categoryNodes.fold(0.0, (total, n) => total + n.openingBalance),
        debit: categoryNodes.fold(0.0, (total, n) => total + n.debit),
        credit: categoryNodes.fold(0.0, (total, n) => total + n.credit),
        balance: categoryNodes.fold(0.0, (total, n) => total + n.balance),
        children: categoryNodes,
        isGroup: true,
        level: 0,
        type: 'type',
      ));
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

  Future<Map<String, double>> _calculateBalances(String companyId, List<AccountModel> accounts, DateTime asOfDate) async {
    Map<String, double> balances = {};
    bool isCurrent = asOfDate.isAfter(DateTime.now().subtract(const Duration(minutes: 5)));

    if (isCurrent) {
      for (var acc in accounts) {
        double bal = acc.currentBalance;
        if (acc.normalBalance == BalanceType.credit) {
          bal = -bal;
        }
        balances[acc.id] = bal;
      }
    } else {
      for (var acc in accounts) {
        double bal = acc.openingBalance;
        if (acc.openingBalanceType == BalanceType.credit) {
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
        final lines = doc.data()['lines'] as List;
        for (var l in lines) {
          String accId = l['accountId'];
          double dr = (l['debit'] as num).toDouble();
          double cr = (l['credit'] as num).toDouble();
          balances[accId] = (balances[accId] ?? 0) + (dr - cr);
        }
      }
    }
    return balances;
  }

  Future<Map<String, double>> _calculateMovements(String companyId, List<AccountModel> accounts, DateTime startDate, DateTime endDate) async {
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
      final lines = doc.data()['lines'] as List;
      for (var l in lines) {
        String accId = l['accountId'];
        double dr = (l['debit'] as num).toDouble();
        double cr = (l['credit'] as num).toDouble();
        movement[accId] = (movement[accId] ?? 0) + (dr - cr);
      }
    }
    return movement;
  }

  Future<Map<String, Map<String, double>>> _calculateDetailedMovements(String companyId, List<AccountModel> accounts, DateTime startDate, DateTime endDate) async {
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
      final lines = doc.data()['lines'] as List;
      for (var l in lines) {
        String accId = l['accountId'];
        double dr = (l['debit'] as num).toDouble();
        double cr = (l['credit'] as num).toDouble();
        
        movements.putIfAbsent(accId, () => {'debit': 0, 'credit': 0});
        movements[accId]!['debit'] = movements[accId]!['debit']! + dr;
        movements[accId]!['credit'] = movements[accId]!['credit']! + cr;
      }
    }
    return movements;
  }
}
