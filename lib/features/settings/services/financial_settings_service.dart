import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_settings_model.dart';

class FinancialSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<FinancialSettingsModel> getSettings(String companyId) async {
    final doc = await _firestore.collection('settings').doc(companyId).get();
    if (doc.exists) {
      return FinancialSettingsModel.fromMap(doc.data()!);
    } else {
      final defaultSettings = FinancialSettingsModel.defaultSettings(companyId);
      await _firestore.collection('settings').doc(companyId).set(defaultSettings.toMap());
      return defaultSettings;
    }
  }

  Future<void> updateSettings(FinancialSettingsModel settings) async {
    await _firestore.collection('settings').doc(settings.companyId).set(settings.toMap(), SetOptions(merge: true));
  }

  Future<String> generateNextDocumentNumber(String companyId, String type) async {
    final docRef = _firestore.collection('settings').doc(companyId);
    
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      Map<String, dynamic> data;
      
      if (!snapshot.exists) {
        final defaultSettings = FinancialSettingsModel.defaultSettings(companyId);
        transaction.set(docRef, defaultSettings.toMap());
        data = defaultSettings.toMap();
      } else {
        data = snapshot.data()!;
      }
      String prefix;
      int currentNumber;
      String fieldName;

      switch (type) {
        case 'invoice':
          prefix = data['invoicePrefix'] ?? 'INV';
          currentNumber = data['nextInvoiceNumber'] ?? 1;
          fieldName = 'nextInvoiceNumber';
          break;
        case 'quotation':
          prefix = data['quotationPrefix'] ?? 'QUO';
          currentNumber = data['nextQuotationNumber'] ?? 1;
          fieldName = 'nextQuotationNumber';
          break;
        case 'purchaseOrder':
          prefix = data['purchaseOrderPrefix'] ?? 'PO';
          currentNumber = data['nextPurchaseOrderNumber'] ?? 1;
          fieldName = 'nextPurchaseOrderNumber';
          break;
        case 'customerPayment':
          prefix = data['customerPaymentPrefix'] ?? 'PAY';
          currentNumber = data['nextCustomerPaymentNumber'] ?? 1;
          fieldName = 'nextCustomerPaymentNumber';
          break;
        case 'supplierPayment':
          prefix = data['supplierPaymentPrefix'] ?? 'SPAY';
          currentNumber = data['nextSupplierPaymentNumber'] ?? 1;
          fieldName = 'nextSupplierPaymentNumber';
          break;
        case 'journal':
          prefix = data['journalPrefix'] ?? 'JV';
          currentNumber = data['nextJournalNumber'] ?? 1;
          fieldName = 'nextJournalNumber';
          break;
        default:
          throw Exception("Invalid document type: $type");
      }

      final nextNumber = currentNumber + 1;
      transaction.update(docRef, {fieldName: nextNumber});

      return '$prefix-${currentNumber.toString().padLeft(5, '0')}';
    });
  }

  Future<bool> isPeriodLocked(String companyId, DateTime date) async {
    final settings = await getSettings(companyId);
    if (!settings.lockPastPeriods) return false;

    final periodStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    
    // If the date's period is lexicographically smaller than the active period, it's considered "past"
    return periodStr.compareTo(settings.activeAccountingPeriod) < 0;
  }
}
