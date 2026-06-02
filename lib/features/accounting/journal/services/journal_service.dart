import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getJournalRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries');
  }

  Stream<List<JournalEntryModel>> getJournalEntries(String companyId) {
    return _getJournalRef(companyId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JournalEntryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addJournalEntry(JournalEntryModel entry) async {
    // Basic validation: Debits must equal Credits
    double totalDebit = 0;
    double totalCredit = 0;
    for (var line in entry.lines) {
      totalDebit += line.debit;
      totalCredit += line.credit;
    }

    if ((totalDebit - totalCredit).abs() > 0.001) {
      throw Exception('Journal entry is not balanced. Total Debit: \$totalDebit, Total Credit: \$totalCredit');
    }

    await _getJournalRef(entry.companyId).doc().set(entry.toMap());
  }
}
