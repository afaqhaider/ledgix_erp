import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/expenses/models/expense_voucher_model.dart';
import 'package:rxdart/rxdart.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

  CollectionReference _getJobsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('jobs');
  }

  Future<String> generateJobNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(companyId, 'job');
  }

  Future<void> createJob(JobModel job) async {
    await _firestore.runTransaction((transaction) async {
      final jobNumber = await _settingsService.getNextDocumentNumberAndIncrement(
        job.companyId,
        'job',
        transaction: transaction,
      );

      final jobRef = _getJobsRef(job.companyId).doc(job.id.isEmpty ? null : job.id);
      final jobToSave = job.copyWith(
        id: jobRef.id,
        jobNumber: jobNumber,
      );

      transaction.set(jobRef, jobToSave.toMap());
    });
  }

  Future<void> updateJob(JobModel job) async {
    await _getJobsRef(job.companyId).doc(job.id).update(job.toMap());
  }

  Stream<List<JobModel>> getJobs(String companyId) {
    return _getJobsRef(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final jobs = snap.docs
          .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // For each job, fetch actual revenue and costs from posted transactions
      final List<JobModel> jobsWithActuals = [];

      for (var job in jobs) {
        double actualRevenue = 0.0;
        double actualCost = 0.0;

        // 1. Revenue from Sales Invoices
        final invSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('salesInvoices')
            .where('jobId', isEqualTo: job.id)
            .where('isPosted', isEqualTo: true)
            .get();
        for (var doc in invSnap.docs) {
          actualRevenue += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }

        // 2. Costs from Supplier Bills
        final billSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('supplierBills')
            .where('jobId', isEqualTo: job.id)
            .where('isPosted', isEqualTo: true)
            .get();
        for (var doc in billSnap.docs) {
          actualCost += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }

        // 3. Costs from Expense Vouchers
        final voucherSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('expenseVouchers')
            .where('jobId', isEqualTo: job.id)
            .where('isPosted', isEqualTo: true)
            .get();
        for (var doc in voucherSnap.docs) {
          actualCost += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }

        jobsWithActuals.add(job.copyWith(
          actualRevenue: actualRevenue,
          actualCost: actualCost,
        ));
      }

      return jobsWithActuals;
    });
  }

  Stream<List<dynamic>> getJobTransactions(String companyId, String jobId) {
    // We combine streams from invoices, bills, and expenses
    final invStream = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices')
        .where('jobId', isEqualTo: jobId)
        .snapshots();

    final billStream = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierBills')
        .where('jobId', isEqualTo: jobId)
        .snapshots();

    final expenseStream = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('expenseVouchers')
        .where('jobId', isEqualTo: jobId)
        .snapshots();

    return Rx.combineLatest3(
      invStream,
      billStream,
      expenseStream,
      (QuerySnapshot invs, QuerySnapshot bills, QuerySnapshot exps) {
        final List<dynamic> all = [];
        all.addAll(invs.docs.map(
          (d) => InvoiceModel.fromMap(d.data() as Map<String, dynamic>, d.id),
        ));
        all.addAll(bills.docs.map(
          (d) => BillModel.fromMap(d.data() as Map<String, dynamic>, d.id),
        ));
        all.addAll(exps.docs.map(
          (d) => ExpenseVoucherModel.fromMap(d.data() as Map<String, dynamic>, d.id),
        ));

        // Sort by date descending
        all.sort((a, b) {
          DateTime dateA;
          if (a is InvoiceModel) {
            dateA = a.invoiceDate;
          } else if (a is BillModel) {
            dateA = a.billDate;
          } else if (a is ExpenseVoucherModel) {
            dateA = a.date;
          } else {
            dateA = DateTime.now();
          }

          DateTime dateB;
          if (b is InvoiceModel) {
            dateB = b.invoiceDate;
          } else if (b is BillModel) {
            dateB = b.billDate;
          } else if (b is ExpenseVoucherModel) {
            dateB = b.date;
          } else {
            dateB = DateTime.now();
          }

          return dateB.compareTo(dateA);
        });

        return all;
      },
    );
  }

  Stream<List<JobModel>> getActiveJobs(String companyId) {
    return _getJobsRef(companyId)
        .where('status', isEqualTo: JobStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
