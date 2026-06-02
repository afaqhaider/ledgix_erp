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

  Future<String> generateNextQuotationNumber(String companyId) async {
    return await _settingsService.generateNextDocumentNumber(companyId, 'quotation');
  }

  Future<void> addQuotation(QuotationModel quotation) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(quotation.companyId, quotation.quotationDate)) {
      throw Exception('Accounting period for this date is locked.');
    }
    await _getQuoRef(quotation.companyId).doc().set(quotation.toMap());
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
    final invoiceNumber = await _invoiceService.generateNextInvoiceNumber(
      quotation.companyId,
    );

    final invoice = InvoiceModel(
      id: '',
      companyId: quotation.companyId,
      invoiceNumber: invoiceNumber,
      customerId: quotation.customerId,
      customerName: quotation.customerName,
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: InvoiceStatus.draft,
      items: quotation.items
          .map(
            (item) => InvoiceLineItemModel(
              description: item.description,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              vatRate: item.vatRate,
              lineSubtotal: item.lineSubtotal,
              lineVat: item.lineVat,
              lineTotal: item.lineTotal,
            ),
          )
          .toList(),
      subtotal: quotation.subtotal,
      vatAmount: quotation.vatAmount,
      totalAmount: quotation.totalAmount,
      balanceDue: quotation.totalAmount,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    // Create the invoice
    final invoiceRef = _firestore
        .collection('companies')
        .doc(quotation.companyId)
        .collection('salesInvoices')
        .doc();
    batch.set(invoiceRef, invoice.toMap());

    // Update the quotation status
    final quoRef = _getQuoRef(quotation.companyId).doc(quotation.id);
    batch.update(quoRef, {'status': QuotationStatus.converted.name});

    await batch.commit();
  }
}
