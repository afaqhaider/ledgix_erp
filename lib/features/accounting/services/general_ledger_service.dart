import 'package:cloud_firestore/cloud_firestore.dart';
import '../journal/models/journal_entry_model.dart';
import '../chart_of_accounts/account_model.dart';
import '../chart_of_accounts/account_service.dart';

class AccountBalance {
  final String accountId;
  final String accountCode;
  final String accountName;
  final AccountType accountType;
  final double totalDebit;
  final double totalCredit;
  final double netBalance;

  AccountBalance({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.totalDebit,
    required this.totalCredit,
    required this.netBalance,
  });
}

class GeneralLedgerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _accountService = AccountService();

  Future<Map<String, AccountBalance>> calculateBalances(
    String companyId,
  ) async {
    // 1. Get all accounts
    final accounts = await _accountService.getAccounts(companyId).first;

    // 2. Get all journal entries (posted)
    final journalEntriesSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .get();

    final journalEntries = journalEntriesSnap.docs
        .map((doc) => JournalEntryModel.fromMap(doc.data(), doc.id))
        .toList();

    Map<String, double> debits = {};
    Map<String, double> credits = {};

    // 3. Add Opening Balances
    for (var acc in accounts) {
      if (acc.openingBalance != 0) {
        if (acc.openingBalanceType == BalanceType.debit) {
          debits[acc.id] = (debits[acc.id] ?? 0) + acc.openingBalance;
        } else {
          credits[acc.id] = (credits[acc.id] ?? 0) + acc.openingBalance;
        }
      }
    }

    // 4. Sum Journal Lines
    for (var entry in journalEntries) {
      for (var line in entry.lines) {
        debits[line.accountId] = (debits[line.accountId] ?? 0) + line.debit;
        credits[line.accountId] = (credits[line.accountId] ?? 0) + line.credit;
      }
    }

    // 5. Build Result
    Map<String, AccountBalance> balances = {};
    for (var acc in accounts) {
      double totalD = debits[acc.id] ?? 0;
      double totalC = credits[acc.id] ?? 0;

      // Calculate net balance based on normal balance type
      double net;
      if (acc.normalBalance == BalanceType.debit) {
        net = totalD - totalC;
      } else {
        net = totalC - totalD;
      }

      balances[acc.id] = AccountBalance(
        accountId: acc.id,
        accountCode: acc.accountCode,
        accountName: acc.accountName,
        accountType: acc.accountType,
        totalDebit: totalD,
        totalCredit: totalC,
        netBalance: net,
      );
    }

    return balances;
  }
}
