import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
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
    debugPrint('DashboardService: getDashboardStats called for $companyId');
    final controller = StreamController<DashboardStats>.broadcast();
    Timer? debounceTimer;

    void performUpdate(String source) async {
      try {
        debugPrint(
          'DashboardService: performUpdate() executing from source: $source',
        );
        debugPrint(
          'Dashboard Debug: Starting update for companyId: $companyId',
        );

        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final prevMonthStart = DateTime(now.year, now.month - 1, 1);
        final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
        final startOfToday = DateTime(now.year, now.month, now.day);

        // 1. Fetch ALL Posted Invoices for Revenue
        final allInvoicesSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .where('isPosted', isEqualTo: true)
            .get();

        double totalRevenue = 0;
        double prevMonthRevenue = 0;

        debugPrint(
          'Dashboard Debug: salesInvoices query returned ${allInvoicesSnap.docs.length} documents',
        );

        if (allInvoicesSnap.docs.isNotEmpty) {
          final first = allInvoicesSnap.docs.first.data();
          debugPrint(
            'Dashboard Debug: First Invoice Sample - isPosted: ${first['isPosted']}, status: ${first['status']}, date: ${first['invoiceDate']}, totalAmount: ${first['totalAmount']}',
          );
        }

        for (var doc in allInvoicesSnap.docs) {
          final data = doc.data();
          final inv = InvoiceModel.fromMap(data, doc.id);
          totalRevenue += inv.totalAmount;

          if (!inv.invoiceDate.isBefore(prevMonthStart)) {
            if (inv.invoiceDate.isBefore(currentMonthStart)) {
              prevMonthRevenue += inv.totalAmount;
            }
          }
        }

        // 2. Fetch ALL Posted Bills for Expenses
        final allBillsSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierBills')
            .where('isPosted', isEqualTo: true)
            .get();

        double totalExpenses = 0;
        double prevMonthExpenses = 0;

        debugPrint(
          'Dashboard Debug: supplierBills query returned ${allBillsSnap.docs.length} documents',
        );

        if (allBillsSnap.docs.isNotEmpty) {
          final first = allBillsSnap.docs.first.data();
          debugPrint(
            'Dashboard Debug: First Bill Sample - isPosted: ${first['isPosted']}, status: ${first['status']}, date: ${first['billDate']}, totalAmount: ${first['totalAmount']}',
          );
        }

        for (var doc in allBillsSnap.docs) {
          final data = doc.data();
          final bill = BillModel.fromMap(data, doc.id);
          totalExpenses += bill.totalAmount;

          if (!bill.billDate.isBefore(prevMonthStart)) {
            if (bill.billDate.isBefore(currentMonthStart)) {
              prevMonthExpenses += bill.totalAmount;
            }
          }
        }

        // 3. Cash Balance from Chart of Accounts
        final accountSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('chartOfAccounts')
            .get();

        double totalCashBalance = 0;
        for (var doc in accountSnap.docs) {
          final data = doc.data();
          if (data['companyId'] == null) data['companyId'] = companyId;
          final account = AccountModel.fromMap(data, doc.id);
          if (account.isGroup || !account.isActive) continue;

          if (account.accountCategory == AccountCategory.cash ||
              account.accountCategory == AccountCategory.bank) {
            totalCashBalance += account.currentBalance;
          }
        }

        // 4. Pending/Overdue
        int pendingInvoices = 0;
        int overdueInvoices = 0;
        final pendingInvSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .where(
              'status',
              whereIn: [
                'draft',
                'pendingApproval',
                'approved',
                'posted',
                'sent',
                'partiallyPaid',
              ],
            )
            .get();

        for (var doc in pendingInvSnap.docs) {
          final inv = InvoiceModel.fromMap(doc.data(), doc.id);
          if (inv.status != InvoiceStatus.paid) {
            pendingInvoices++;
            if (inv.dueDate.isBefore(now)) {
              overdueInvoices++;
            }
          }
        }

        // 5. Approvals
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

        int approvedToday = 0;
        for (var doc in approvedTodaySnap.docs) {
          final history = doc.data()['history'] as List?;
          if (history != null && history.isNotEmpty) {
            final lastAction = history.last;
            if (lastAction is Map && lastAction['timestamp'] is Timestamp) {
              if ((lastAction['timestamp'] as Timestamp).toDate().isAfter(
                startOfToday,
              )) {
                approvedToday++;
              }
            }
          }
        }

        // 6. Chart Data
        List<double> revenueChartData = List.filled(6, 0.0);
        List<double> expenseChartData = List.filled(6, 0.0);
        List<double> cashFlowData = List.filled(6, 0.0);
        List<String> chartLabels = [];

        for (int i = 5; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 1);
          chartLabels.add(DateFormat('MMM').format(date));
        }

        for (var doc in allInvoicesSnap.docs) {
          final inv = InvoiceModel.fromMap(doc.data(), doc.id);
          final monthDiff =
              (now.year - inv.invoiceDate.year) * 12 +
              (now.month - inv.invoiceDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            revenueChartData[5 - monthDiff] += inv.totalAmount;
          }
        }

        for (var doc in allBillsSnap.docs) {
          final bill = BillModel.fromMap(doc.data(), doc.id);
          final monthDiff =
              (now.year - bill.billDate.year) * 12 +
              (now.month - bill.billDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            expenseChartData[5 - monthDiff] += bill.totalAmount;
          }
        }

        final cpSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('customerPayments')
            .where('isPosted', isEqualTo: true)
            .where(
              'paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo),
            )
            .get();

        final spSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierPayments')
            .where('isPosted', isEqualTo: true)
            .where(
              'paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo),
            )
            .get();

        for (var doc in cpSnap.docs) {
          final p = CustomerPaymentModel.fromMap(doc.data(), doc.id);
          final monthDiff =
              (now.year - p.paymentDate.year) * 12 +
              (now.month - p.paymentDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            cashFlowData[5 - monthDiff] += p.amount;
          }
        }
        for (var doc in spSnap.docs) {
          final p = SupplierPaymentModel.fromMap(doc.data(), doc.id);
          final monthDiff =
              (now.year - p.paymentDate.year) * 12 +
              (now.month - p.paymentDate.month);
          if (monthDiff >= 0 && monthDiff < 6) {
            cashFlowData[5 - monthDiff] -= p.amount;
          }
        }

        if (!controller.isClosed) {
          controller.add(
            DashboardStats(
              totalRevenue: totalRevenue,
              prevMonthRevenue: prevMonthRevenue,
              totalExpenses: totalExpenses,
              prevMonthExpenses: prevMonthExpenses,
              totalProfit: totalRevenue - totalExpenses,
              prevMonthProfit: prevMonthRevenue - prevMonthExpenses,
              cashBalance: totalCashBalance,
              pendingInvoicesCount: pendingInvoices,
              overdueInvoicesCount: overdueInvoices,
              pendingApprovalsCount: pendingAppSnap.docs.length,
              approvedTodayCount: approvedToday,
              rejectedDocsCount: rejectedSnap.docs.length,
              revenueChartData: revenueChartData,
              expenseChartData: expenseChartData,
              chartLabels: chartLabels,
              cashFlowData: cashFlowData.any((e) => e != 0) ? cashFlowData : [],
              cashFlowLabels: chartLabels,
            ),
          );
        }
      } catch (error, stackTrace) {
        debugPrint('Dashboard CRITICAL Error: $error');
        debugPrint('Dashboard StackTrace: $stackTrace');
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    void update(String source) {
      debugPrint(
        'DashboardService: update() requested from source: $source (debouncing)',
      );
      debounceTimer?.cancel();
      debounceTimer = Timer(
        const Duration(milliseconds: 300),
        () => performUpdate(source),
      );
    }

    // Listen to changes
    final sub1 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .snapshots()
        .listen((_) => update('salesInvoices change'));
    final sub2 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierBills')
        .snapshots()
        .listen((_) => update('supplierBills change'));
    final sub3 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('bankAccounts')
        .snapshots()
        .listen((_) => update('bankAccounts change'));
    final sub4 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('approvalRequests')
        .snapshots()
        .listen((_) => update('approvalRequests change'));
    final sub5 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments')
        .snapshots()
        .listen((_) => update('customerPayments change'));
    final sub6 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments')
        .snapshots()
        .listen((_) => update('supplierPayments change'));
    final sub7 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .snapshots()
        .listen((_) => update('chartOfAccounts change'));

    controller.onCancel = () {
      debugPrint(
        'DashboardService: Stream cancelled, disposing listeners and timer',
      );
      debounceTimer?.cancel();
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      sub4.cancel();
      sub5.cancel();
      sub6.cancel();
      sub7.cancel();
    };

    performUpdate('initial call');
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
