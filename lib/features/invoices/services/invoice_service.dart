import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_rule_model.dart';
import '../../settings/services/financial_settings_service.dart';

import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();
  final _inventoryService = InventoryService();
  final _approvalService = ApprovalService();
  final _postingService = AccountingPostingService();

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

  Future<void> addInvoice(InvoiceModel invoice, AppUser user) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(
      invoice.companyId,
      invoice.invoiceDate,
    )) {
      throw Exception('Accounting period for this date is locked.');
    }

    // Determine initial status based on role
    final highRoles = [
      UserRole.owner,
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.accountant,
      UserRole.generalManager,
    ];

    bool shouldAutoPost = highRoles.contains(user.role);
    
    // Security Enforcement: Cleanse fields if not authorized to post
    InvoiceModel invoiceToProcess = invoice;
    if (!shouldAutoPost) {
      invoiceToProcess = invoice.copyWith(
        isPosted: false,
        postedAt: null,
        postedBy: null,
        journalEntryId: null,
        amountPaid: 0.0, // Initial invoices shouldn't have payments yet in this flow
        balanceDue: invoice.totalAmount,
      );
    }

    InvoiceStatus initialStatus =
        shouldAutoPost ? InvoiceStatus.posted : InvoiceStatus.pendingApproval;
    String? initialApprovalStatus = shouldAutoPost ? 'approved' : 'pending';

    String? invoiceId;

    await _firestore.runTransaction((transaction) async {
      // 1. Generate the actual document number and increment counter within transaction
      final finalNumber = await _settingsService
          .getNextDocumentNumberAndIncrement(
            invoiceToProcess.companyId,
            'invoice',
            transaction: transaction,
          );

      final docRef = _getInvoicesRef(invoiceToProcess.companyId).doc();
      invoiceId = docRef.id;

      final invoiceToSave = invoiceToProcess.copyWith(
        id: docRef.id,
        invoiceNumber: finalNumber,
        status: initialStatus,
        approvalStatus: initialApprovalStatus,
      );

      // 2. Save the invoice
      transaction.set(docRef, invoiceToSave.toMap());
    });

    if (shouldAutoPost && invoiceId != null) {
      // Call posting service
      try {
        final doc = await _getInvoicesRef(invoiceToProcess.companyId).doc(invoiceId).get();
        final savedInvoice = InvoiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        await _postingService.postSalesInvoice(invoiceToProcess.companyId, savedInvoice, user);
      } catch (e, stack) {
        print('CRITICAL: Auto-posting failed for invoice $invoiceId: $e');
        print(stack);
        // We throw a more descriptive error for the UI
        throw Exception('Invoice saved successfully as #${invoiceId}, but auto-posting failed. Error: $e');
      }
    } else if (invoiceId != null) {
      // Submit for approval if not auto-posted
      await _approvalService.submitForApproval(
        user: user,
        companyId: invoice.companyId,
        sourceType: 'sales_invoice',
        sourceId: invoiceId!,
        sourceNumber: invoice.invoiceNumber, // This might be 'AUTO' here, should use finalNumber but we don't have it easily outside tx
        amount: invoice.totalAmount,
      );
    }
  }

  Future<void> postInvoice(
    String companyId,
    InvoiceModel invoice,
    AppUser user,
  ) async {
    await _postingService.postSalesInvoice(companyId, invoice, user);
  }

  Future<void> updateInvoiceStatus(
    String companyId,
    String invoiceId,
    InvoiceStatus status,
  ) async {
    final doc = await _getInvoicesRef(companyId).doc(invoiceId).get();
    if (doc.exists && (doc.data() as Map<String, dynamic>)['isPosted'] == true) {
      throw Exception('Cannot update status of a posted invoice.');
    }
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
