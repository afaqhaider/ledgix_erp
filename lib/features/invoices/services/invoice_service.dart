import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import '../../settings/services/financial_settings_service.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

  CollectionReference _getInvoicesRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('salesInvoices');
  }

  Stream<List<InvoiceModel>> getInvoices(String companyId) {
    return _getInvoicesRef(
      companyId,
    ).orderBy('invoiceDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return InvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<String> generateNextInvoiceNumber(String companyId) async {
    return await _settingsService.generateNextDocumentNumber(companyId, 'invoice');
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(invoice.companyId, invoice.invoiceDate)) {
      throw Exception('Accounting period for this date is locked.');
    }

    await _getInvoicesRef(invoice.companyId).doc().set(invoice.toMap());
  }

  Future<void> updateInvoiceStatus(
    String companyId,
    String invoiceId,
    InvoiceStatus status,
  ) async {
    await _getInvoicesRef(
      companyId,
    ).doc(invoiceId).update({'status': status.name});
  }

  Future<void> deleteInvoice(String companyId, String invoiceId) async {
    final doc = await _getInvoicesRef(companyId).doc(invoiceId).get();
    if (!doc.exists) return;

    final invoice = InvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    if (invoice.isPosted) {
      throw Exception('Cannot delete a posted invoice. Reverse the entry via Journal if needed.');
    }

    // Check if any payments are linked to this invoice
    final paymentsSnap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('customerPayments')
        .where('invoiceId', isEqualTo: invoiceId)
        .limit(1)
        .get();

    if (paymentsSnap.docs.isNotEmpty) {
      throw Exception('Cannot delete invoice with existing payments. Delete payments first.');
    }

    await _getInvoicesRef(companyId).doc(invoiceId).delete();
  }
}
