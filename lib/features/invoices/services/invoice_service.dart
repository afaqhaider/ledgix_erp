import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_rule_model.dart';
import '../../settings/services/financial_settings_service.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();
  final _inventoryService = InventoryService();
  final _approvalService = ApprovalService();

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

  Future<String> previewNextInvoiceNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(
      companyId,
      'invoice',
    );
  }

  Future<String> generateNextInvoiceNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(
      companyId,
      'invoice',
    );
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(
      invoice.companyId,
      invoice.invoiceDate,
    )) {
      throw Exception('Accounting period for this date is locked.');
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Generate the actual document number and increment counter within transaction
      final finalNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            invoice.companyId,
            'invoice',
            transaction: transaction,
          );

      final docRef = _getInvoicesRef(invoice.companyId).doc();

      final invoiceToSave = invoice.copyWith(
        id: docRef.id,
        invoiceNumber: finalNumber,
      );

      // 2. Save the invoice
      transaction.set(docRef, invoiceToSave.toMap());
    });
  }

  Future<void> postInvoice(String companyId, String invoiceId) async {
    final doc = await _getInvoicesRef(companyId).doc(invoiceId).get();
    if (!doc.exists) throw Exception('Invoice not found');

    final invoice = InvoiceModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
    if (invoice.isPosted) throw Exception('Invoice already posted');

    // ENFORCE APPROVAL
    if (invoice.approvalStatus != 'approved') {
      // Check if it actually needs approval
      final rule = await _approvalService.findMatchingRule(
        companyId: companyId,
        module: ApprovalModule.salesInvoices,
        amount: invoice.totalAmount,
      );

      if (rule != null && rule.requiredApproverRoles.isNotEmpty) {
        throw Exception(
          'This invoice requires approval before it can be posted.',
        );
      }
    }

    // 1. Process Inventory Updates and Calculate COGS
    for (var item in invoice.items) {
      if (item.productId != null && item.productId!.isNotEmpty) {
        await _inventoryService.recordSale(
          companyId: companyId,
          productId: item.productId!,
          quantity: item.quantity,
        );
      }
    }

    // 2. Mark Invoice as Posted
    await _getInvoicesRef(companyId).doc(invoiceId).update({
      'isPosted': true,
      'approvalStatus': 'approved', // Automatically approve on post for now
    });
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

    final invoice = InvoiceModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
    if (invoice.isPosted) {
      throw Exception(
        'Cannot delete a posted invoice. Reverse the entry via Journal if needed.',
      );
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
      throw Exception(
        'Cannot delete invoice with existing payments. Delete payments first.',
      );
    }

    await _getInvoicesRef(companyId).doc(invoiceId).delete();
  }
}
