import 'package:cloud_firestore/cloud_firestore.dart';
import '../../accounting/journal/models/journal_entry_model.dart';
import '../../accounting/journal/models/journal_line_model.dart';
import '../../settings/models/financial_settings_model.dart';
import '../models/expense_voucher_model.dart';

class ExpenseVoucherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getVouchersRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('expenseVouchers');
  }

  Future<void> createVoucher(ExpenseVoucherModel voucher) async {
    await _firestore.runTransaction((transaction) async {
      final voucherRef = _getVouchersRef(voucher.companyId).doc(voucher.id);
      transaction.set(voucherRef, voucher.toMap());

      final settingsRef = _firestore
          .collection('companies')
          .doc(voucher.companyId)
          .collection('settings')
          .doc('financial');
      
      transaction.update(settingsRef, {
        'nextExpenseVoucherNumber': FieldValue.increment(1),
      });
    });
  }

  Future<String> generateVoucherNumber(String companyId) async {
    final settingsDoc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('financial')
        .get();

    if (!settingsDoc.exists) return 'EXP-00001';

    final settings = FinancialSettingsModel.fromMap(settingsDoc.data()!, companyId);
    return '${settings.expenseVoucherPrefix}-${settings.nextExpenseVoucherNumber.toString().padLeft(5, '0')}';
  }

  Future<void> postVoucher(String companyId, String voucherId, String userId) async {
    final voucherDoc = await _getVouchersRef(companyId).doc(voucherId).get();
    if (!voucherDoc.exists) throw Exception('Voucher not found');
    
    final voucher = ExpenseVoucherModel.fromMap(voucherDoc.data() as Map<String, dynamic>, voucherId);
    if (voucher.status == ExpenseVoucherStatus.posted) throw Exception('Voucher already posted');

    await _firestore.runTransaction((transaction) async {
      // 1. Prepare Journal Lines
      List<JournalLineModel> journalLines = [];

      // Debits: Expenses
      for (var line in voucher.lines) {
        journalLines.add(JournalLineModel(
          accountId: line.accountId,
          accountName: line.accountName,
          accountCode: '', // Would need to fetch code if required
          memo: line.description,
          debit: line.amount,
          credit: 0,
          jobId: line.jobId ?? voucher.jobId,
          jobNumber: line.jobNumber ?? voucher.jobNumber,
          jobName: line.jobName ?? voucher.jobName,
        ));
      }

      // Debit: VAT Input if applicable
      if (voucher.totalVat > 0) {
        // Need to find VAT Input account. For now, assume a system search or standard name.
        // In a real implementation, we should fetch VAT Input account from settings.
        final vatSnap = await _firestore
            .collection('companies')
            .doc(companyId)
            .collection('chartOfAccounts')
            .where('accountCategory', isEqualTo: 'vatInput')
            .limit(1)
            .get();
        
        if (vatSnap.docs.isNotEmpty) {
          final vatAcc = vatSnap.docs.first;
          journalLines.add(JournalLineModel(
            accountId: vatAcc.id,
            accountName: vatAcc.data()['accountName'] ?? 'VAT Input',
            accountCode: vatAcc.data()['accountCode'] ?? '',
            memo: 'VAT on Expense ${voucher.voucherNumber}',
            debit: voucher.totalVat,
            credit: 0,
          ));
        }
      }

      // Credit: Bank/Cash
      journalLines.add(JournalLineModel(
        accountId: voucher.fromAccountId,
        accountName: voucher.fromAccountName,
        accountCode: '',
        memo: voucher.description,
        debit: 0,
        credit: voucher.totalAmount + voucher.totalVat,
        jobId: voucher.jobId,
        jobNumber: voucher.jobNumber,
        jobName: voucher.jobName,
      ));

      // 2. Create Journal Entry
      final journalRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('journalEntries')
          .doc();
      
      final journalEntry = JournalEntryModel(
        id: journalRef.id,
        companyId: companyId,
        date: voucher.date,
        reference: voucher.voucherNumber,
        description: voucher.description,
        lines: journalLines,
        status: JournalStatus.posted,
        createdBy: userId,
        createdAt: DateTime.now(),
        sourceType: 'expenseVoucher',
        sourceId: voucherId,
        sourceNumber: voucher.voucherNumber,
        jobId: voucher.jobId,
        jobNumber: voucher.jobNumber,
        jobName: voucher.jobName,
      );

      transaction.set(journalRef, journalEntry.toMap());

      // 3. Update Voucher Status
      transaction.update(voucherDoc.reference, {
        'status': ExpenseVoucherStatus.posted.name,
        'postedByUserId': userId,
        'postedAt': FieldValue.serverTimestamp(),
      });

      // 4. Update Account Balances (Denormalized)
      for (var line in journalLines) {
        final accRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('chartOfAccounts')
            .doc(line.accountId);
        
        // For balance update, we need to know normal balance but for now just use (dr - cr)
        // Adjusting currentBalance field
        transaction.update(accRef, {
          'currentBalance': FieldValue.increment(line.debit - line.credit),
        });
      }

      // 5. Update Bank Account Balance if applicable
      final bankAccRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('bankAccounts')
          .doc(voucher.fromAccountId);
      
      final bankDoc = await transaction.get(bankAccRef);
      if (bankDoc.exists) {
        transaction.update(bankAccRef, {
          'currentBalance': FieldValue.increment(-(voucher.totalAmount + voucher.totalVat)),
        });
      }

      // 6. Audit Log
      final logRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('auditLogs')
          .doc();
      
      transaction.set(logRef, {
        'actionType': 'post',
        'documentType': 'expenseVoucher',
        'documentId': voucherId,
        'documentNumber': voucher.voucherNumber,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'details': 'Posted expense voucher for ${voucher.totalAmount + voucher.totalVat}',
      });
    });
  }

  Stream<List<ExpenseVoucherModel>> getVouchers(String companyId) {
    return _getVouchersRef(companyId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ExpenseVoucherModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
