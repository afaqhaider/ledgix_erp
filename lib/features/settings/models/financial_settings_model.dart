import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryValuationMethod { fifo, weightedAverage }

class FinancialSettingsModel {
  final String companyId;
  final DateTime financialYearStart;
  final DateTime financialYearEnd;
  final String activeAccountingPeriod;
  final bool lockPastPeriods;
  final InventoryValuationMethod inventoryValuationMethod;

  // Document Numbering
  final String invoicePrefix;
  final String quotationPrefix;
  final String purchaseOrderPrefix;
  final String receiptPrefix;
  final String supplierPaymentPrefix;
  final String journalPrefix;
  final String billPrefix;

  final int nextInvoiceNumber;
  final int nextQuotationNumber;
  final int nextPurchaseOrderNumber;
  final int nextReceiptNumber;
  final int nextSupplierPaymentNumber;
  final int nextJournalNumber;
  final int nextBillNumber;

  FinancialSettingsModel({
    required this.companyId,
    required this.financialYearStart,
    required this.financialYearEnd,
    required this.activeAccountingPeriod,
    this.lockPastPeriods = false,
    this.inventoryValuationMethod = InventoryValuationMethod.fifo,
    this.invoicePrefix = 'INV',
    this.quotationPrefix = 'QUO',
    this.purchaseOrderPrefix = 'PO',
    this.receiptPrefix = 'REC',
    this.supplierPaymentPrefix = 'SPAY',
    this.journalPrefix = 'JV',
    this.billPrefix = 'BILL',
    this.nextInvoiceNumber = 1,
    this.nextQuotationNumber = 1,
    this.nextPurchaseOrderNumber = 1,
    this.nextReceiptNumber = 1,
    this.nextSupplierPaymentNumber = 1,
    this.nextJournalNumber = 1,
    this.nextBillNumber = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'financialYearStart': Timestamp.fromDate(financialYearStart),
      'financialYearEnd': Timestamp.fromDate(financialYearEnd),
      'activeAccountingPeriod': activeAccountingPeriod,
      'lockPastPeriods': lockPastPeriods,
      'inventoryValuationMethod': inventoryValuationMethod.name,
      'invoicePrefix': invoicePrefix,
      'quotationPrefix': quotationPrefix,
      'purchaseOrderPrefix': purchaseOrderPrefix,
      'receiptPrefix': receiptPrefix,
      'supplierPaymentPrefix': supplierPaymentPrefix,
      'journalPrefix': journalPrefix,
      'billPrefix': billPrefix,
      'nextInvoiceNumber': nextInvoiceNumber,
      'nextQuotationNumber': nextQuotationNumber,
      'nextPurchaseOrderNumber': nextPurchaseOrderNumber,
      'nextReceiptNumber': nextReceiptNumber,
      'nextSupplierPaymentNumber': nextSupplierPaymentNumber,
      'nextJournalNumber': nextJournalNumber,
      'nextBillNumber': nextBillNumber,
    };
  }

  factory FinancialSettingsModel.fromMap(
    Map<String, dynamic> map, [
    String? id,
  ]) {
    final now = DateTime.now();
    return FinancialSettingsModel(
      companyId: map['companyId'] ?? id ?? '',
      financialYearStart:
          (map['financialYearStart'] as Timestamp?)?.toDate() ??
          DateTime(now.year, 1, 1),
      financialYearEnd:
          (map['financialYearEnd'] as Timestamp?)?.toDate() ??
          DateTime(now.year, 12, 31),
      activeAccountingPeriod:
          map['activeAccountingPeriod'] ??
          '${now.year}-${now.month.toString().padLeft(2, '0')}',
      lockPastPeriods: map['lockPastPeriods'] ?? false,
      inventoryValuationMethod: InventoryValuationMethod.values.firstWhere(
        (e) => e.name == map['inventoryValuationMethod'],
        orElse: () => InventoryValuationMethod.fifo,
      ),
      invoicePrefix: map['invoicePrefix'] ?? 'INV',
      quotationPrefix: map['quotationPrefix'] ?? 'QUO',
      purchaseOrderPrefix: map['purchaseOrderPrefix'] ?? 'PO',
      receiptPrefix: map['receiptPrefix'] ?? map['customerPaymentPrefix'] ?? 'REC',
      supplierPaymentPrefix: map['supplierPaymentPrefix'] ?? 'SPAY',
      journalPrefix: map['journalPrefix'] ?? 'JV',
      billPrefix: map['billPrefix'] ?? 'BILL',
      nextInvoiceNumber: map['nextInvoiceNumber'] ?? 1,
      nextQuotationNumber: map['nextQuotationNumber'] ?? 1,
      nextPurchaseOrderNumber: map['nextPurchaseOrderNumber'] ?? 1,
      nextReceiptNumber: map['nextReceiptNumber'] ?? map['nextCustomerPaymentNumber'] ?? 1,
      nextSupplierPaymentNumber: map['nextSupplierPaymentNumber'] ?? 1,
      nextJournalNumber: map['nextJournalNumber'] ?? 1,
      nextBillNumber: map['nextBillNumber'] ?? 1,
    );
  }

  FinancialSettingsModel copyWith({
    String? companyId,
    DateTime? financialYearStart,
    DateTime? financialYearEnd,
    String? activeAccountingPeriod,
    bool? lockPastPeriods,
    InventoryValuationMethod? inventoryValuationMethod,
    String? invoicePrefix,
    String? quotationPrefix,
    String? purchaseOrderPrefix,
    String? receiptPrefix,
    String? supplierPaymentPrefix,
    String? journalPrefix,
    String? billPrefix,
    int? nextInvoiceNumber,
    int? nextQuotationNumber,
    int? nextPurchaseOrderNumber,
    int? nextReceiptNumber,
    int? nextSupplierPaymentNumber,
    int? nextJournalNumber,
    int? nextBillNumber,
  }) {
    return FinancialSettingsModel(
      companyId: companyId ?? this.companyId,
      financialYearStart: financialYearStart ?? this.financialYearStart,
      financialYearEnd: financialYearEnd ?? this.financialYearEnd,
      activeAccountingPeriod:
          activeAccountingPeriod ?? this.activeAccountingPeriod,
      lockPastPeriods: lockPastPeriods ?? this.lockPastPeriods,
      inventoryValuationMethod:
          inventoryValuationMethod ?? this.inventoryValuationMethod,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      quotationPrefix: quotationPrefix ?? this.quotationPrefix,
      purchaseOrderPrefix: purchaseOrderPrefix ?? this.purchaseOrderPrefix,
      receiptPrefix:
          receiptPrefix ?? this.receiptPrefix,
      supplierPaymentPrefix:
          supplierPaymentPrefix ?? this.supplierPaymentPrefix,
      journalPrefix: journalPrefix ?? this.journalPrefix,
      billPrefix: billPrefix ?? this.billPrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      nextQuotationNumber: nextQuotationNumber ?? this.nextQuotationNumber,
      nextPurchaseOrderNumber:
          nextPurchaseOrderNumber ?? this.nextPurchaseOrderNumber,
      nextReceiptNumber:
          nextReceiptNumber ?? this.nextReceiptNumber,
      nextSupplierPaymentNumber:
          nextSupplierPaymentNumber ?? this.nextSupplierPaymentNumber,
      nextJournalNumber: nextJournalNumber ?? this.nextJournalNumber,
      nextBillNumber: nextBillNumber ?? this.nextBillNumber,
    );
  }

  factory FinancialSettingsModel.defaultSettings(String companyId) {
    final now = DateTime.now();
    return FinancialSettingsModel(
      companyId: companyId,
      financialYearStart: DateTime(now.year, 1, 1),
      financialYearEnd: DateTime(now.year, 12, 31),
      activeAccountingPeriod:
          '${now.year}-${now.month.toString().padLeft(2, '0')}',
    );
  }
}
