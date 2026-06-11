import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import '../../../settings/services/financial_settings_service.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();
  final _approvalService = ApprovalService();

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

  Stream<List<JournalEntryModel>> getJournalEntriesByAccount(
    String companyId,
    String accountId,
  ) {
    return _getJournalRef(companyId)
        .where('accountIds', arrayContains: accountId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
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

  Future<void> addJournalEntry(
    JournalEntryModel entry,
    AppUser user, {
    bool shouldPost = false,
  }) async {
    if (shouldPost &&
        await _settingsService.isPeriodLocked(entry.companyId, entry.date)) {
      throw Exception('Accounting period for this date is locked.');
    }

    // Determine initial status based on role and action
    final highRoles = [
      UserRole.owner,
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.accountant,
      UserRole.generalManager,
    ];

    bool isAuthorizedToPost = highRoles.contains(user.role);
    bool actualPost = shouldPost && isAuthorizedToPost;

    JournalStatus finalStatus = JournalStatus.draft;
    String? initialApprovalStatus = 'pending';

    if (actualPost) {
      finalStatus = JournalStatus.posted;
      initialApprovalStatus = 'approved';
    } else if (shouldPost && !isAuthorizedToPost) {
      initialApprovalStatus = 'pending';
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
          throw Exception(
            'Account "${line.accountName}" is a group account and cannot be posted to.',
          );
        }
        if (!allowPosting) {
          throw Exception(
            'Account "${line.accountName}" does not allow posting.',
          );
        }
      }
    }

    String? entryId;
    String? finalJournalNumber;

    await _firestore.runTransaction((transaction) async {
      // 1. Generate final number and increment within transaction
      finalJournalNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            entry.companyId,
            'journal',
            transaction: transaction,
          );

      final docRef = _getJournalRef(entry.companyId).doc();
      entryId = docRef.id;

      final entryToSave = entry.copyWith(
        id: docRef.id,
        reference: finalJournalNumber!,
        status: finalStatus,
        approvalStatus: initialApprovalStatus,
      );

      // 2. Save entry
      transaction.set(docRef, entryToSave.toMap());

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

    if (shouldPost && !isAuthorizedToPost && entryId != null) {
      await _approvalService.submitForApproval(
        user: user,
        companyId: entry.companyId,
        sourceType: 'journal_entry',
        sourceId: entryId!,
        sourceNumber: finalJournalNumber ?? 'AUTO',
        amount: totalDebit,
      );
    }
  }

  Future<void> updateJournalEntry(
    JournalEntryModel entry,
    AppUser user, {
    bool shouldPost = false,
  }) async {
    if (shouldPost &&
        await _settingsService.isPeriodLocked(entry.companyId, entry.date)) {
      throw Exception('Accounting period for this date is locked.');
    }

    final docRef = _getJournalRef(entry.companyId).doc(entry.id);
    final existingDoc = await docRef.get();
    if (!existingDoc.exists) throw Exception('Journal entry not found.');

    final existingEntry = JournalEntryModel.fromMap(
      existingDoc.data() as Map<String, dynamic>,
      existingDoc.id,
    );

    if (existingEntry.status == JournalStatus.posted && !shouldPost) {
       // If it was already posted, we generally shouldn't allow un-posting by just saving as draft
       // unless there's a specific unpost action.
    }

    await docRef.update(entry.toMap());

    // If it was just posted now, we might need to handle accounting impact if not already handled by a service
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
