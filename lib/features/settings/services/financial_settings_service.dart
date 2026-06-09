import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_settings_model.dart';

class FinancialSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<FinancialSettingsModel> getSettings(String companyId) async {
    final doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('financial')
        .get();
    if (doc.exists) {
      return FinancialSettingsModel.fromMap(doc.data()!);
    } else {
      final defaultSettings = FinancialSettingsModel.defaultSettings(companyId);
      await _firestore
          .collection('companies')
          .doc(companyId)
          .collection('settings')
          .doc('financial')
          .set(defaultSettings.toMap());
      return defaultSettings;
    }
  }

  Future<void> updateSettings(FinancialSettingsModel settings) async {
    await _firestore
        .collection('companies')
        .doc(settings.companyId)
        .collection('settings')
        .doc('financial')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  Stream<FinancialSettingsModel> streamSettings(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('financial')
        .snapshots()
        .map((doc) => doc.exists 
            ? FinancialSettingsModel.fromMap(doc.data()!) 
            : FinancialSettingsModel.defaultSettings(companyId));
  }

  Future<String> previewNextDocumentNumber(
    String companyId,
    String type,
  ) async {
    final settings = await getSettings(companyId);
    String prefix;
    int currentNumber;

    switch (type) {
      case 'invoice':
        prefix = settings.invoicePrefix;
        currentNumber = settings.nextInvoiceNumber;
        break;
      case 'quotation':
        prefix = settings.quotationPrefix;
        currentNumber = settings.nextQuotationNumber;
        break;
      case 'purchaseOrder':
        prefix = settings.purchaseOrderPrefix;
        currentNumber = settings.nextPurchaseOrderNumber;
        break;
      case 'receipt':
      case 'customerPayment':
        prefix = settings.receiptPrefix;
        currentNumber = settings.nextReceiptNumber;
        break;
      case 'supplierPayment':
        prefix = settings.supplierPaymentPrefix;
        currentNumber = settings.nextSupplierPaymentNumber;
        break;
      case 'journal':
        prefix = settings.journalPrefix;
        currentNumber = settings.nextJournalNumber;
        break;
      case 'bill':
        prefix = settings.billPrefix;
        currentNumber = settings.nextBillNumber;
        break;
      default:
        throw Exception("Invalid document type: $type");
    }

    return '$prefix-${currentNumber.toString().padLeft(5, '0')}';
  }

  /// Gets the next number and increments it within a transaction.
  /// If [transaction] is provided, it uses it, otherwise starts a new one.
  Future<String> getNextDocumentNumberAndIncrement(
    String companyId,
    String type, {
    Transaction? transaction,
  }) async {
    final docRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('financial');

    if (transaction != null) {
      return await _processIncrement(transaction, docRef, companyId, type);
    } else {
      return await _firestore.runTransaction((tx) async {
        return await _processIncrement(tx, docRef, companyId, type);
      });
    }
  }

  Future<String> _processIncrement(
    Transaction tx,
    DocumentReference docRef,
    String companyId,
    String type,
  ) async {
    final snapshot = await tx.get(docRef);
    Map<String, dynamic> data;

    if (!snapshot.exists) {
      final defaultSettings = FinancialSettingsModel.defaultSettings(companyId);
      tx.set(docRef, defaultSettings.toMap());
      data = defaultSettings.toMap();
    } else {
      data = snapshot.data()! as Map<String, dynamic>;
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
      case 'receipt':
      case 'customerPayment':
        prefix =
            data['receiptPrefix'] ?? data['customerPaymentPrefix'] ?? 'REC';
        currentNumber =
            data['nextReceiptNumber'] ?? data['nextCustomerPaymentNumber'] ?? 1;
        fieldName = 'nextReceiptNumber';
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
      case 'bill':
        prefix = data['billPrefix'] ?? 'BILL';
        currentNumber = data['nextBillNumber'] ?? 1;
        fieldName = 'nextBillNumber';
        break;
      default:
        throw Exception("Invalid document type: $type");
    }

    final nextNumber = currentNumber + 1;
    tx.update(docRef, {fieldName: nextNumber});

    return '$prefix-${currentNumber.toString().padLeft(5, '0')}';
  }

  Future<bool> isPeriodLocked(String companyId, DateTime date) async {
    final settings = await getSettings(companyId);
    if (!settings.lockPastPeriods) return false;

    final periodStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';

    return periodStr.compareTo(settings.activeAccountingPeriod) < 0;
  }
}
