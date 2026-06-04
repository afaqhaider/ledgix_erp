import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/banking/models/bank_reconciliation_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';

class BankReconciliationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getEntriesRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('bankStatementEntries');
  }

  Stream<List<BankStatementEntry>> getStatementEntries({
    required String companyId,
    required String bankAccountId,
    DateTime? startDate,
    DateTime? endDate,
    ReconciliationStatus? status,
  }) {
    Query query = _getEntriesRef(
      companyId,
    ).where('bankAccountId', isEqualTo: bankAccountId);

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => BankStatementEntry.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    });
  }

  Future<void> importEntries(
    String companyId,
    List<BankStatementEntry> entries,
  ) async {
    final batch = _firestore.batch();
    for (var entry in entries) {
      final docRef = _getEntriesRef(companyId).doc();
      batch.set(docRef, entry.toMap()..['id'] = docRef.id);
    }
    await batch.commit();
  }

  Future<void> matchEntry({
    required String companyId,
    required String entryId,
    required String transactionId,
    required String transactionType,
    required String userId,
  }) async {
    await _getEntriesRef(companyId).doc(entryId).update({
      'matchedTransactionId': transactionId,
      'matchedTransactionType': transactionType,
      'status': ReconciliationStatus.matched.name,
      'matchedBy': userId,
      'matchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unmatchEntry({
    required String companyId,
    required String entryId,
    required String userId,
  }) async {
    await _getEntriesRef(companyId).doc(entryId).update({
      'matchedTransactionId': null,
      'matchedTransactionType': null,
      'status': ReconciliationStatus.unmatched.name,
      'unmatchedBy': userId,
      'unmatchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ignoreEntry(String companyId, String entryId) async {
    await _getEntriesRef(
      companyId,
    ).doc(entryId).update({'status': ReconciliationStatus.ignored.name});
  }

  // Matching Engine
  Future<List<Map<String, dynamic>>> getPotentialMatches({
    required String companyId,
    required String linkedChartAccountId,
    required BankStatementEntry entry,
  }) async {
    // Search in Journal Entries
    // For bank statement:
    // credit (money in) -> ERP debit to bank account
    // debit (money out) -> ERP credit to bank account

    double targetAmount = entry.credit > 0 ? entry.credit : entry.debit;
    bool isMoneyIn = entry.credit > 0;

    // Search for journal entries within a date range (e.g. +/- 7 days)
    DateTime start = entry.date.subtract(const Duration(days: 7));
    DateTime end = entry.date.add(const Duration(days: 7));

    final journalDocs = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    List<Map<String, dynamic>> matches = [];

    for (var doc in journalDocs.docs) {
      final journal = JournalEntryModel.fromMap(doc.data(), doc.id);
      for (var line in journal.lines) {
        if (line.accountId == linkedChartAccountId) {
          double lineAmount = isMoneyIn ? line.debit : line.credit;

          if (lineAmount == targetAmount) {
            matches.add({
              'transaction': journal,
              'line': line,
              'type': 'journal_entry',
              'matchScore': _calculateMatchScore(entry, journal, line),
            });
          }
        }
      }
    }

    // Sort by match score descending
    matches.sort(
      (a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int),
    );

    return matches;
  }

  Future<List<JournalEntryModel>> searchTransactions({
    required String companyId,
    required String linkedChartAccountId,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
  }) async {
    Query firestoreQuery = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries');

    if (startDate != null) {
      firestoreQuery = firestoreQuery.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      firestoreQuery = firestoreQuery.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    final snapshot = await firestoreQuery.get();
    List<JournalEntryModel> results = [];

    for (var doc in snapshot.docs) {
      final journal = JournalEntryModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      bool matches = false;

      // Filter by linked account
      bool hasAccount = journal.lines.any(
        (l) => l.accountId == linkedChartAccountId,
      );
      if (!hasAccount) continue;

      if (query != null && query.isNotEmpty) {
        String q = query.toLowerCase();
        if (journal.reference.toLowerCase().contains(q) ||
            journal.description.toLowerCase().contains(q)) {
          matches = true;
        }
      } else {
        matches = true;
      }

      if (amount != null && amount > 0) {
        bool hasAmount = journal.lines.any(
          (l) =>
              l.accountId == linkedChartAccountId &&
              (l.debit == amount || l.credit == amount),
        );
        if (!hasAmount) matches = false;
      }

      if (matches) {
        results.add(journal);
      }
    }

    return results;
  }

  int _calculateMatchScore(
    BankStatementEntry entry,
    JournalEntryModel journal,
    dynamic line,
  ) {
    int score = 0;
    // Date match
    if (entry.date.year == journal.date.year &&
        entry.date.month == journal.date.month &&
        entry.date.day == journal.date.day) {
      score += 50;
    }

    // Reference match
    if (entry.reference != null && entry.reference!.isNotEmpty) {
      if (journal.reference.contains(entry.reference!) ||
          entry.reference!.contains(journal.reference)) {
        score += 30;
      }
    }

    // Description/Memo match
    if (entry.description.toLowerCase().contains(
          journal.description.toLowerCase(),
        ) ||
        journal.description.toLowerCase().contains(
          entry.description.toLowerCase(),
        )) {
      score += 20;
    }

    return score;
  }
}
