import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import '../../../settings/services/financial_settings_service.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

  CollectionReference _getJournalRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries');
  }

  Stream<List<JournalEntryModel>> getJournalEntries(String companyId) {
    return _getJournalRef(
      companyId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return JournalEntryModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<String> generateNextJournalNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(
      companyId,
      'journal',
    );
  }

  Future<void> addJournalEntry(JournalEntryModel entry) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(entry.companyId, entry.date)) {
      throw Exception('Accounting period for this date is locked.');
    }

    // Basic validation: Debits must equal Credits
    double totalDebit = 0;
    double totalCredit = 0;
    for (var line in entry.lines) {
      totalDebit += line.debit;
      totalCredit += line.credit;
    }

    if ((totalDebit - totalCredit).abs() > 0.001) {
      throw Exception(
        'Journal entry is not balanced. Total Debit: $totalDebit, Total Credit: $totalCredit',
      );
    }

    // Validate that none of the accounts are group accounts
    for (var line in entry.lines) {
      final accDoc = await _firestore
          .collection('companies')
          .doc(entry.companyId)
          .collection('chartOfAccounts')
          .doc(line.accountId)
          .get();
      
      if (accDoc.exists) {
        final isGroup = accDoc.data()?['isGroup'] ?? false;
        final allowPosting = accDoc.data()?['allowPosting'] ?? true;
        if (isGroup) {
          throw Exception('Account "${line.accountName}" is a group account and cannot be posted to.');
        }
        if (!allowPosting) {
          throw Exception('Account "${line.accountName}" does not allow posting.');
        }
      }
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Generate final number and increment within transaction
      final finalNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            entry.companyId,
            'journal',
            transaction: transaction,
          );

      final docRef = _getJournalRef(entry.companyId).doc();
      final entryWithId = entry.copyWith(id: docRef.id, reference: finalNumber);

      // 2. Save entry
      transaction.set(docRef, entryWithId.toMap());

      // Update source document if applicable
      if (entry.sourceId != null && entry.sourceType != null) {
        await _updateSourceDocumentInTransaction(
          transaction,
          entry.companyId,
          entry.sourceType!,
          entry.sourceId!,
          docRef.id,
        );
      }
    });
  }

  Future<void> _updateSourceDocumentInTransaction(
    Transaction tx,
    String companyId,
    String sourceType,
    String sourceId,
    String journalEntryId,
  ) async {
    String collection;
    switch (sourceType.toLowerCase()) {
      case 'invoice':
      case 'salesinvoice':
        collection = 'salesInvoices';
        break;
      case 'bill':
      case 'supplierbill':
        collection = 'supplierBills';
        break;
      case 'quotation':
        collection = 'quotations';
        break;
      case 'purchaseorder':
        collection = 'purchaseOrders';
        break;
      default:
        return;
    }

    final sourceRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection(collection)
        .doc(sourceId);

    tx.update(sourceRef, {'journalEntryId': journalEntryId});
  }

  Future<void> deleteJournalEntry(String companyId, String entryId) async {
    final doc = await _getJournalRef(companyId).doc(entryId).get();
    if (!doc.exists) return;

    final entry = JournalEntryModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
    if (entry.status == JournalStatus.posted) {
      throw Exception(
        'Cannot delete a posted journal entry. Reverse it instead.',
      );
    }

    await _getJournalRef(companyId).doc(entryId).delete();
  }
}
