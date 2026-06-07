import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class DashboardStats {
  final double totalRevenue;
  final double prevMonthRevenue;
  final double totalExpenses;
  final double prevMonthExpenses;
  final double totalProfit;
  final double prevMonthProfit;
  final double cashBalance;

  final int pendingInvoicesCount;
  final int overdueInvoicesCount;
  final int pendingApprovalsCount;
  final int approvedTodayCount;
  final int rejectedDocsCount;

  // Chart Data
  final List<double> revenueChartData;
  final List<double> expenseChartData;
  final List<String> chartLabels;
  final List<double> cashFlowData;
  final List<String> cashFlowLabels;

  DashboardStats({
    this.totalRevenue = 0,
    this.prevMonthRevenue = 0,
    this.totalExpenses = 0,
    this.prevMonthExpenses = 0,
    this.totalProfit = 0,
    this.prevMonthProfit = 0,
    this.cashBalance = 0,
    this.pendingInvoicesCount = 0,
    this.overdueInvoicesCount = 0,
    this.pendingApprovalsCount = 0,
    this.approvedTodayCount = 0,
    this.rejectedDocsCount = 0,
    this.revenueChartData = const [],
    this.expenseChartData = const [],
    this.chartLabels = const [],
    this.cashFlowData = const [],
    this.cashFlowLabels = const [],
  });

  String get revenueTrend => _calculateTrend(totalRevenue, prevMonthRevenue);
  String get expenseTrend => _calculateTrend(totalExpenses, prevMonthExpenses);
  String get profitTrend => _calculateTrend(totalProfit, prevMonthProfit);

  bool get isRevenueUp => totalRevenue >= prevMonthRevenue;
  bool get isExpenseUp => totalExpenses >= prevMonthExpenses;
  bool get isProfitUp => totalProfit >= prevMonthProfit;

  static String _calculateTrend(double current, double previous) {
    if (previous == 0) return 'No previous month data';
    final diff = ((current - previous) / previous) * 100;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)}% vs last month';
  }
}

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DashboardStats> getDashboardStats(String companyId) {
    final controller = StreamController<DashboardStats>();

    void update() async {
      try {
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final prevMonthStart = DateTime(now.year, now.month - 1, 1);
        final startOfToday = DateTime(now.year, now.month, now.day);
        final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

        // Fetch Invoices for Revenue and counts
        final invSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .get();

        // Fetch Bills for Expenses
        final billSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierBills')
            .where('isPosted', isEqualTo: true)
            .get();

        // Fetch Bank Accounts for Cash Balance
        final bankSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('bankAccounts')
            .where('isActive', isEqualTo: true)
            .get();

        final accountSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('chartOfAccounts')
            .get();

        // Approval counts
        final pendingAppSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('approvalRequests')
            .where('status', isEqualTo: 'pending')
            .get();

        final approvedTodaySnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('approvalRequests')
            .where('status', isEqualTo: 'approved')
            .get();

        final rejectedSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('approvalRequests')
            .where('status', isEqualTo: 'rejected')
            .get();

        // Fetch Cash Movements for Cash Flow Chart
        final customerPaymentsSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('customerPayments')
            .where('isPosted', isEqualTo: true)
            .where('paymentDate', isGreaterThanOrEqualTo: sixMonthsAgo)
            .get();

        final supplierPaymentsSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierPayments')
            .where('isPosted', isEqualTo: true)
            .where('paymentDate', isGreaterThanOrEqualTo: sixMonthsAgo)
            .get();

        double revenue = 0;
        double prevRevenue = 0;
        int pendingInvoices = 0;
        int overdueInvoices = 0;

        for (var doc in invSnap.docs) {
          final inv = InvoiceModel.fromMap(doc.data(), doc.id);
          if (inv.isPosted) {
            if (inv.invoiceDate.isAfter(currentMonthStart) ||
                inv.invoiceDate.isAtSameMomentAs(currentMonthStart)) {
              revenue += inv.totalAmount;
            } else if (inv.invoiceDate.isAfter(prevMonthStart) ||
                inv.invoiceDate.isAtSameMomentAs(prevMonthStart)) {
              prevRevenue += inv.totalAmount;
            }
          }

          if (inv.status != InvoiceStatus.paid &&
              inv.status != InvoiceStatus.cancelled) {
            pendingInvoices++;
            if (inv.dueDate.isBefore(now)) {
              overdueInvoices++;
            }
          }
        }

        double expenses = 0;
        double prevExpenses = 0;
        for (var doc in billSnap.docs) {
          final bill = BillModel.fromMap(doc.data(), doc.id);
          if (bill.billDate.isAfter(currentMonthStart) ||
              bill.billDate.isAtSameMomentAs(currentMonthStart)) {
            expenses += bill.totalAmount;
          } else if (bill.billDate.isAfter(prevMonthStart) ||
              bill.billDate.isAtSameMomentAs(prevMonthStart)) {
            prevExpenses += bill.totalAmount;
          }
        }

        double cashBalance = 0;
        for (var doc in bankSnap.docs) {
          final bank = BankAccountModel.fromMap(doc.data(), doc.id);
          cashBalance += bank.currentBalance;
        }

        double ledgerRevenue = 0;
        double ledgerExpenses = 0;
        double ledgerCash = 0;
        for (var doc in accountSnap.docs) {
          final data = doc.data();
          if (data['companyId'] == null) data['companyId'] = companyId;
          final account = AccountModel.fromMap(data, doc.id);
          if (account.isGroup || !account.isActive) continue;

          switch (account.accountType) {
            case AccountType.income:
            case AccountType.otherIncome:
              ledgerRevenue += account.currentBalance;
              break;
            case AccountType.expense:
            case AccountType.costOfSales:
            case AccountType.otherExpense:
              ledgerExpenses += account.currentBalance;
              break;
            default:
              break;
          }

          if (account.accountCategory == AccountCategory.cash ||
              account.accountCategory == AccountCategory.bank) {
            ledgerCash += account.currentBalance;
          }
        }

        if (revenue == 0 && ledgerRevenue != 0) revenue = ledgerRevenue;
        if (expenses == 0 && ledgerExpenses != 0) expenses = ledgerExpenses;
        if (cashBalance == 0 && ledgerCash != 0) cashBalance = ledgerCash;

        int approvedToday = 0;
        for (var doc in approvedTodaySnap.docs) {
          final history = doc.data()['history'] as List?;
          if (history == null || history.isEmpty) continue;
          final lastAction = history.last;
          if (lastAction is! Map) continue;
          final rawTimestamp = lastAction['timestamp'];
          if (rawTimestamp is! Timestamp) continue;
          if (rawTimestamp.toDate().isAfter(startOfToday)) {
            approvedToday++;
          }
        }

        // Fetch chart data (last 6 months)
        final chartInvSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .where('isPosted', isEqualTo: true)
            .where('invoiceDate', isGreaterThanOrEqualTo: sixMonthsAgo)
            .get();

        final chartBillSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierBills')
            .where('isPosted', isEqualTo: true)
            .where('billDate', isGreaterThanOrEqualTo: sixMonthsAgo)
            .get();

        List<double> revenueChartData = List.filled(6, 0.0);
        List<double> expenseChartData = List.filled(6, 0.0);
        List<double> cashFlowData = List.filled(6, 0.0);
        List<String> chartLabels = [];

        for (int i = 5; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 1);
          chartLabels.add(DateFormat('MMM').format(date));
        }

        for (var doc in chartInvSnap.docs) {
          final inv = InvoiceModel.fromMap(doc.data(), doc.id);
          final monthDiff =
              (now.year - inv.invoiceDate.year) * 12 +
              (now.month - inv.invoiceDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            revenueChartData[5 - monthDiff] += inv.totalAmount;
          }
        }

        for (var doc in chartBillSnap.docs) {
          final bill = BillModel.fromMap(doc.data(), doc.id);
          final monthDiff =
              (now.year - bill.billDate.year) * 12 +
              (now.month - bill.billDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            expenseChartData[5 - monthDiff] += bill.totalAmount;
          }
        }

        // Calculate Cash Flow (Inflows - Outflows)
        for (var doc in customerPaymentsSnap.docs) {
          final payment = CustomerPaymentModel.fromMap(doc.data(), doc.id);
          final monthDiff =
              (now.year - payment.paymentDate.year) * 12 +
              (now.month - payment.paymentDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            cashFlowData[5 - monthDiff] += payment.amount;
          }
        }

        for (var doc in supplierPaymentsSnap.docs) {
          final payment = SupplierPaymentModel.fromMap(doc.data(), doc.id);
          final monthDiff =
              (now.year - payment.paymentDate.year) * 12 +
              (now.month - payment.paymentDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            cashFlowData[5 - monthDiff] -= payment.amount;
          }
        }

        // If all cash flow data is zero, send empty list to trigger empty state in UI
        final finalCashFlowData = cashFlowData.any((e) => e != 0)
            ? cashFlowData
            : <double>[];

        if (!controller.isClosed) {
          controller.add(
            DashboardStats(
              totalRevenue: revenue,
              prevMonthRevenue: prevRevenue,
              totalExpenses: expenses,
              prevMonthExpenses: prevExpenses,
              totalProfit: revenue - expenses,
              prevMonthProfit: prevRevenue - prevExpenses,
              cashBalance: cashBalance,
              pendingInvoicesCount: pendingInvoices,
              overdueInvoicesCount: overdueInvoices,
              pendingApprovalsCount: pendingAppSnap.docs.length,
              approvedTodayCount: approvedToday,
              rejectedDocsCount: rejectedSnap.docs.length,
              revenueChartData: revenueChartData,
              expenseChartData: expenseChartData,
              chartLabels: chartLabels,
              cashFlowData: finalCashFlowData,
              cashFlowLabels: chartLabels,
            ),
          );
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    // Listen to changes
    final sub1 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .snapshots()
        .listen((_) => update());
    final sub2 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierBills')
        .snapshots()
        .listen((_) => update());
    final sub3 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('bankAccounts')
        .snapshots()
        .listen((_) => update());
    final sub4 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('approvalRequests')
        .snapshots()
        .listen((_) => update());
    final sub5 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments')
        .snapshots()
        .listen((_) => update());
    final sub6 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments')
        .snapshots()
        .listen((_) => update());
    final sub7 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .snapshots()
        .listen((_) => update());

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      sub4.cancel();
      sub5.cancel();
      sub6.cancel();
      sub7.cancel();
    };

    update();
    return controller.stream;
  }

  Stream<List<CustomerPaymentModel>> getRecentCustomerPayments(
    String companyId,
  ) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments')
        .orderBy('paymentDate', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CustomerPaymentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<QuotationModel>> getLatestQuotations(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('quotations')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => QuotationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
