import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/invoices/services/invoice_service.dart';
import '../../settings/services/financial_settings_service.dart';

class QuotationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _invoiceService = InvoiceService();
  final _settingsService = FinancialSettingsService();

  CollectionReference _getQuoRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('quotations');
  }

  Stream<List<QuotationModel>> getQuotations(String companyId) {
    return _getQuoRef(
      companyId,
    ).orderBy('quotationDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return QuotationModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<String> previewNextQuotationNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(
      companyId,
      'quotation',
    );
  }

  Future<void> addQuotation(QuotationModel quotation) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(
      quotation.companyId,
      quotation.quotationDate,
    )) {
      throw Exception('Accounting period for this date is locked.');
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Generate final number and increment within transaction
      final finalNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            quotation.companyId,
            'quotation',
            transaction: transaction,
          );

      final docRef = _getQuoRef(quotation.companyId).doc();
      final finalQuotation = quotation.copyWith(
        id: docRef.id,
        quotationNumber: finalNumber,
      );

      // 2. Save quotation
      transaction.set(docRef, finalQuotation.toMap());
    });
  }

  Future<void> updateQuotationStatus(
    String companyId,
    String quotationId,
    QuotationStatus status,
  ) async {
    await _getQuoRef(
      companyId,
    ).doc(quotationId).update({'status': status.name});
  }

  Future<void> convertToInvoice(QuotationModel quotation) async {
    // Conversion usually happens as a new transaction
    // We can use the existing addInvoice which handles transactions
    final invoice = InvoiceModel(
      id: '',
      companyId: quotation.companyId,
      invoiceNumber: 'AUTO', // Will be replaced by service
      customerId: quotation.customerId,
      customerName: quotation.customerName,
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: InvoiceStatus.draft,
      items: quotation.items.map((item) {
        return InvoiceLineItemModel(
          productId: item.productId,
          accountId: item.accountId,
          accountName: item.accountName,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          vatRate: item.vatRate,
          lineSubtotal: item.lineSubtotal,
          lineVat: item.lineVat,
          lineTotal: item.lineTotal,
        );
      }).toList(),
      subtotal: quotation.subtotal,
      vatAmount: quotation.vatAmount,
      totalAmount: quotation.totalAmount,
      balanceDue: quotation.totalAmount,
      createdAt: DateTime.now(),
    );

    await _invoiceService.addInvoice(invoice);

    // Update the quotation status
    await updateQuotationStatus(
      quotation.companyId,
      quotation.id,
      QuotationStatus.converted,
    );
  }
}
