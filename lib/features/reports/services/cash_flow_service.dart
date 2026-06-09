import 'package:cloud_firestore/cloud_firestore.dart';
import '../../accounting/chart_of_accounts/account_model.dart';

class CashFlowData {
  final double operatingActivities;
  final double investingActivities;
  final double financingActivities;
  final double openingCash;
  final double closingCash;

  CashFlowData({
    required this.operatingActivities,
    required this.investingActivities,
    required this.financingActivities,
    required this.openingCash,
    required this.closingCash,
  });

  double get netCashIncrease => operatingActivities + investingActivities + financingActivities;
}

class CashFlowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<CashFlowData> getCashFlowReport(String companyId, DateTime start, DateTime end) async {
    // 1. Fetch all accounts
    final accountsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('chartOfAccounts')
        .get();
    
    final Map<String, CashFlowSection> accountSections = {
      for (var doc in accountsSnap.docs) doc.id: CashFlowSection.values.firstWhere(
        (e) => e.name == doc.data()['cashFlowSection'], orElse: () => CashFlowSection.none
      )
    };
    
    final Map<String, AccountCategory> accountCategories = {
      for (var doc in accountsSnap.docs) doc.id: AccountCategory.values.firstWhere(
        (e) => e.name == doc.data()['accountCategory'], orElse: () => AccountCategory.uncategorized
      )
    };

    // 2. Calculate Opening Cash (Balance at start date)
    // For simplicity, we assume we have a way to get historical balance or use current - movements.
    // In a real IAS 7 indirect method, we'd look at changes in Balance Sheet accounts.
    // Here we'll use a simplified direct-ish movement from Journal Entries.
    
    final journalSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('journalEntries')
        .where('status', isEqualTo: 'posted')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    double operating = 0;
    double investing = 0;
    double financing = 0;

    for (var doc in journalSnap.docs) {
      final lines = (doc.data()['lines'] as List? ?? []);
      
      // Look for movements in Bank/Cash accounts
      double cashMovement = 0;
      for (var line in lines) {
        final cat = accountCategories[line['accountId']];
        if (cat == AccountCategory.cash || cat == AccountCategory.bank) {
          cashMovement += (line['debit'] as num).toDouble() - (line['credit'] as num).toDouble();
        }
      }

      if (cashMovement != 0) {
        // The other side of this entry determines the section
        for (var line in lines) {
          final section = accountSections[line['accountId']];
          if (section != CashFlowSection.none) {
            final impact = (line['credit'] as num).toDouble() - (line['debit'] as num).toDouble();
            // Note: If we debited cash, the other side was credited.
            // Direct method: Receipts (Cr Revenue) = +Cash
            
            if (section == CashFlowSection.operating) {
              operating += impact;
            } else if (section == CashFlowSection.investing) {
              investing += impact;
            } else if (section == CashFlowSection.financing) {
              financing += impact;
            }
          }
        }
      }
    }

    // This is a placeholder for real Opening/Closing cash calculation
    double openingCash = 0; 
    double closingCash = openingCash + operating + investing + financing;

    return CashFlowData(
      operatingActivities: operating,
      investingActivities: investing,
      financingActivities: financing,
      openingCash: openingCash,
      closingCash: closingCash,
    );
  }
}
