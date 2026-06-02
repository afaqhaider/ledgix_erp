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
    return await _settingsService.generateNextDocumentNumber(companyId, 'journal');
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

    await _getJournalRef(entry.companyId).doc().set(entry.toMap());
  }

  Future<void> deleteJournalEntry(String companyId, String entryId) async {
    final doc = await _getJournalRef(companyId).doc(entryId).get();
    if (!doc.exists) return;

    final entry = JournalEntryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    if (entry.status == JournalStatus.posted) {
      throw Exception('Cannot delete a posted journal entry. Reverse it instead.');
    }

    await _getJournalRef(companyId).doc(entryId).delete();
  }
}
