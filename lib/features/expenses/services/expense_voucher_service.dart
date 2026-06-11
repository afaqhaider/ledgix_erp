import 'package:cloud_firestore/cloud_firestore.dart';
import '../../accounting/journal/models/journal_entry_model.dart';
import '../../accounting/journal/models/journal_line_model.dart';
import '../../settings/services/financial_settings_service.dart';
import '../models/expense_voucher_model.dart';

class ExpenseVoucherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

  CollectionReference _getVouchersRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('expenseVouchers');
  }

  Future<void> createVoucher(ExpenseVoucherModel voucher) async {
    await _firestore.runTransaction((transaction) async {
      final voucherNumber = await _settingsService.getNextDocumentNumberAndIncrement(
        voucher.companyId,
        'expenseVoucher',
        transaction: transaction,
      );

      final voucherRef = _getVouchersRef(voucher.companyId).doc(voucher.id.isEmpty ? null : voucher.id);
      final voucherToSave = voucher.copyWith(
        id: voucherRef.id,
        voucherNumber: voucherNumber,
      );

      transaction.set(voucherRef, voucherToSave.toMap());
    });
  }

  Future<String> generateVoucherNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(companyId, 'expenseVoucher');
  }

  Future<void> postVoucher(String companyId, String voucherId, String userId) async {
    final voucherDoc = await _getVouchersRef(companyId).doc(voucherId).get();
    if (!voucherDoc.exists) throw Exception('Voucher not found');
    
    final voucher = ExpenseVoucherModel.fromMap(voucherDoc.data() as Map<String, dynamic>, voucherId);
    if (voucher.status == ExpenseVoucherStatus.posted) throw Exception('Voucher already posted');

    // Fetch VAT Input account outside transaction
    DocumentSnapshot? vatAccDoc;
    if (voucher.totalVat > 0) {
      final vatSnap = await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('chartOfAccounts')
          .where('accountCategory', isEqualTo: 'vatInput')
          .limit(1)
          .get();
      if (vatSnap.docs.isNotEmpty) {
        vatAccDoc = vatSnap.docs.first;
      }
    }

    await _firestore.runTransaction((transaction) async {
      // 1. ALL READS FIRST
      final bankAccRef = _firestore
          .collection('companies')
          .doc(companyId)
          .collection('bankAccounts')
          .doc(voucher.fromAccountId);
      
      final bankDoc = await transaction.get(bankAccRef);

      // 2. Prepare Journal Lines
      List<JournalLineModel> journalLines = [];

      // Debits: Expenses
      for (var line in voucher.lines) {
        journalLines.add(JournalLineModel(
          accountId: line.accountId,
          accountName: line.accountName,
          accountCode: '',
          memo: line.description,
          debit: line.amount,
          credit: 0,
          jobId: line.jobId ?? voucher.jobId,
          jobNumber: line.jobNumber ?? voucher.jobNumber,
          jobName: line.jobName ?? voucher.jobName,
        ));
      }

      // Debit: VAT Input if applicable
      if (voucher.totalVat > 0 && vatAccDoc != null) {
        final data = vatAccDoc.data() as Map<String, dynamic>;
        journalLines.add(JournalLineModel(
          accountId: vatAccDoc.id,
          accountName: data['accountName'] ?? 'VAT Input',
          accountCode: data['accountCode'] ?? '',
          memo: 'VAT on Expense ${voucher.voucherNumber}',
          debit: voucher.totalVat,
          credit: 0,
        ));
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

      // 3. EXECUTE WRITES
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

      transaction.update(voucherDoc.reference, {
        'status': ExpenseVoucherStatus.posted.name,
        'postedByUserId': userId,
        'postedAt': FieldValue.serverTimestamp(),
      });

      for (var line in journalLines) {
        final accRef = _firestore
            .collection('companies')
            .doc(companyId)
            .collection('chartOfAccounts')
            .doc(line.accountId);
        transaction.update(accRef, {
          'currentBalance': FieldValue.increment(line.debit - line.credit),
        });
      }

      if (bankDoc.exists) {
        transaction.update(bankAccRef, {
          'currentBalance': FieldValue.increment(-(voucher.totalAmount + voucher.totalVat)),
        });
      }

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

  Future<void> updateVoucher(ExpenseVoucherModel voucher) async {
    await _getVouchersRef(voucher.companyId).doc(voucher.id).update(voucher.toMap());
  }

  Future<void> deleteVoucher(String companyId, String voucherId) async {
    final doc = await _getVouchersRef(companyId).doc(voucherId).get();
    if (!doc.exists) return;
    
    final voucher = ExpenseVoucherModel.fromMap(doc.data() as Map<String, dynamic>, voucherId);
    if (voucher.status == ExpenseVoucherStatus.posted) {
      throw Exception('Cannot delete a posted expense voucher. Void it instead.');
    }
    
    await _getVouchersRef(companyId).doc(voucherId).delete();
  }
}
