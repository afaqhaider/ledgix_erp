import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialSettingsModel {
  final String companyId;
  final DateTime financialYearStart;
  final DateTime financialYearEnd;
  final String activeAccountingPeriod;
  final bool lockPastPeriods;

  // Document Numbering
  final String invoicePrefix;
  final String quotationPrefix;
  final String purchaseOrderPrefix;
  final String customerPaymentPrefix;
  final String supplierPaymentPrefix;
  final String journalPrefix;

  final int nextInvoiceNumber;
  final int nextQuotationNumber;
  final int nextPurchaseOrderNumber;
  final int nextCustomerPaymentNumber;
  final int nextSupplierPaymentNumber;
  final int nextJournalNumber;

  FinancialSettingsModel({
    required this.companyId,
    required this.financialYearStart,
    required this.financialYearEnd,
    required this.activeAccountingPeriod,
    this.lockPastPeriods = false,
    this.invoicePrefix = 'INV',
    this.quotationPrefix = 'QUO',
    this.purchaseOrderPrefix = 'PO',
    this.customerPaymentPrefix = 'PAY',
    this.supplierPaymentPrefix = 'SPAY',
    this.journalPrefix = 'JV',
    this.nextInvoiceNumber = 1,
    this.nextQuotationNumber = 1,
    this.nextPurchaseOrderNumber = 1,
    this.nextCustomerPaymentNumber = 1,
    this.nextSupplierPaymentNumber = 1,
    this.nextJournalNumber = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'financialYearStart': Timestamp.fromDate(financialYearStart),
      'financialYearEnd': Timestamp.fromDate(financialYearEnd),
      'activeAccountingPeriod': activeAccountingPeriod,
      'lockPastPeriods': lockPastPeriods,
      'invoicePrefix': invoicePrefix,
      'quotationPrefix': quotationPrefix,
      'purchaseOrderPrefix': purchaseOrderPrefix,
      'customerPaymentPrefix': customerPaymentPrefix,
      'supplierPaymentPrefix': supplierPaymentPrefix,
      'journalPrefix': journalPrefix,
      'nextInvoiceNumber': nextInvoiceNumber,
      'nextQuotationNumber': nextQuotationNumber,
      'nextPurchaseOrderNumber': nextPurchaseOrderNumber,
      'nextCustomerPaymentNumber': nextCustomerPaymentNumber,
      'nextSupplierPaymentNumber': nextSupplierPaymentNumber,
      'nextJournalNumber': nextJournalNumber,
    };
  }

  factory FinancialSettingsModel.fromMap(Map<String, dynamic> map) {
    return FinancialSettingsModel(
      companyId: map['companyId'] ?? '',
      financialYearStart: (map['financialYearStart'] as Timestamp).toDate(),
      financialYearEnd: (map['financialYearEnd'] as Timestamp).toDate(),
      activeAccountingPeriod: map['activeAccountingPeriod'] ?? '',
      lockPastPeriods: map['lockPastPeriods'] ?? false,
      invoicePrefix: map['invoicePrefix'] ?? 'INV',
      quotationPrefix: map['quotationPrefix'] ?? 'QUO',
      purchaseOrderPrefix: map['purchaseOrderPrefix'] ?? 'PO',
      customerPaymentPrefix: map['customerPaymentPrefix'] ?? 'PAY',
      supplierPaymentPrefix: map['supplierPaymentPrefix'] ?? 'SPAY',
      journalPrefix: map['journalPrefix'] ?? 'JV',
      nextInvoiceNumber: map['nextInvoiceNumber'] ?? 1,
      nextQuotationNumber: map['nextQuotationNumber'] ?? 1,
      nextPurchaseOrderNumber: map['nextPurchaseOrderNumber'] ?? 1,
      nextCustomerPaymentNumber: map['nextCustomerPaymentNumber'] ?? 1,
      nextSupplierPaymentNumber: map['nextSupplierPaymentNumber'] ?? 1,
      nextJournalNumber: map['nextJournalNumber'] ?? 1,
    );
  }

  factory FinancialSettingsModel.defaultSettings(String companyId) {
    final now = DateTime.now();
    return FinancialSettingsModel(
      companyId: companyId,
      financialYearStart: DateTime(now.year, 1, 1),
      financialYearEnd: DateTime(now.year, 12, 31),
      activeAccountingPeriod: '${now.year}-${now.month.toString().padLeft(2, '0')}',
    );
  }
}
