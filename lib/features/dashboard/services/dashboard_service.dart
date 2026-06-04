import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'dart:async';

class DashboardStats {
  final double totalRevenue;
  final double totalExpenses;
  final double totalProfit;
  final int pendingInvoicesCount;
  final int overdueInvoicesCount;
  final int pendingApprovalsCount;
  final int approvedTodayCount;
  final int rejectedDocsCount;

  DashboardStats({
    this.totalRevenue = 0,
    this.totalExpenses = 0,
    this.totalProfit = 0,
    this.pendingInvoicesCount = 0,
    this.overdueInvoicesCount = 0,
    this.pendingApprovalsCount = 0,
    this.approvedTodayCount = 0,
    this.rejectedDocsCount = 0,
  });
}

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DashboardStats> getDashboardStats(String companyId) {
    final controller = StreamController<DashboardStats>();

    void update() async {
      try {
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);

        final invSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .get();

        final supSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierPayments')
            .where('isPosted', isEqualTo: true)
            .get();

        final pendingAppSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('approval_requests')
            .where('status', isEqualTo: 'pending')
            .get();

        final approvedTodaySnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('approval_requests')
            .where('status', isEqualTo: 'approved')
            .get();

        final rejectedSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('approval_requests')
            .where('status', isEqualTo: 'rejected')
            .get();

        double revenue = 0;
        int pendingInvoices = 0;
        int overdueInvoices = 0;

        for (var doc in invSnap.docs) {
          final inv = InvoiceModel.fromMap(doc.data(), doc.id);
          if (inv.isPosted) {
            revenue += inv.totalAmount;
          }
          if (inv.status != InvoiceStatus.paid) {
            pendingInvoices++;
            if (inv.dueDate.isBefore(now)) {
              overdueInvoices++;
            }
          }
        }

        double expenses = 0;
        for (var doc in supSnap.docs) {
          expenses += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        }

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

        if (!controller.isClosed) {
          controller.add(
            DashboardStats(
              totalRevenue: revenue,
              totalExpenses: expenses,
              totalProfit: revenue - expenses,
              pendingInvoicesCount: pendingInvoices,
              overdueInvoicesCount: overdueInvoices,
              pendingApprovalsCount: pendingAppSnap.docs.length,
              approvedTodayCount: approvedToday,
              rejectedDocsCount: rejectedSnap.docs.length,
            ),
          );
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    // Listen to changes in all related collections
    final sub1 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .snapshots()
        .listen((_) => update());
    final sub2 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments')
        .snapshots()
        .listen((_) => update());
    final sub3 = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('approval_requests')
        .snapshots()
        .listen((_) => update());

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
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

  Stream<List<SupplierPaymentModel>> getRecentSupplierPayments(
    String companyId,
  ) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments')
        .orderBy('paymentDate', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SupplierPaymentModel.fromMap(doc.data(), doc.id))
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

  Stream<List<JournalEntryModel>> getRecentJournalEntries(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
