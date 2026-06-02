import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';

class DashboardStats {
  final double totalRevenue;
  final double totalExpenses;
  final double totalProfit;
  final int pendingInvoicesCount;
  final int overdueInvoicesCount;
  final int pendingApprovalsCount;

  DashboardStats({
    this.totalRevenue = 0,
    this.totalExpenses = 0,
    this.totalProfit = 0,
    this.pendingInvoicesCount = 0,
    this.overdueInvoicesCount = 0,
    this.pendingApprovalsCount = 0,
  });
}

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DashboardStats> getDashboardStats(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .snapshots()
        .asyncMap((invSnap) async {
      final now = DateTime.now();
      
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

      // Expenses from Supplier Payments
      final paymentsSnap = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('supplierPayments')
          .where('isPosted', isEqualTo: true)
          .get();
      
      double expenses = 0;
      for (var doc in paymentsSnap.docs) {
        expenses += (doc.data()['amount'] as num).toDouble();
      }

      // Pending Approvals
      final approvalsSnap = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('approvals')
          .where('status', isEqualTo: 'pending')
          .get();

      return DashboardStats(
        totalRevenue: revenue,
        totalExpenses: expenses,
        totalProfit: revenue - expenses,
        pendingInvoicesCount: pendingInvoices,
        overdueInvoicesCount: overdueInvoices,
        pendingApprovalsCount: approvalsSnap.docs.length,
      );
    });
  }

  Stream<List<CustomerPaymentModel>> getRecentCustomerPayments(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments')
        .orderBy('paymentDate', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => CustomerPaymentModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<SupplierPaymentModel>> getRecentSupplierPayments(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments')
        .orderBy('paymentDate', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => SupplierPaymentModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<QuotationModel>> getLatestQuotations(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('quotations')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => QuotationModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<JournalEntryModel>> getRecentJournalEntries(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id)).toList());
  }
}
