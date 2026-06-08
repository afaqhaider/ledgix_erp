import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

import 'package:ledgixerp/features/invoices/services/invoice_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  // ...
  final InvoiceModel invoice;
  final AppUser user;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    required this.user,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _postingService = AccountingPostingService();
  final _approvalService = ApprovalService();
  final _companyService = CompanyService();
  final _invoiceService = InvoiceService();
  bool _isPosting = false;
  late InvoiceModel _currentInvoice;
  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
    _loadCompany();
  }

  void _loadCompany() {
    _companyService.getCompany(widget.user.companyId!).first.then((company) {
      if (mounted) setState(() => _company = company);
    });
  }

  Future<void> _submitForApproval() async {
    setState(() => _isPosting = true);
    try {
      await _approvalService.submitForApproval(
        user: widget.user,
        companyId: widget.user.companyId!,
        sourceType: 'sales_invoice',
        sourceId: _currentInvoice.id,
        sourceNumber: _currentInvoice.invoiceNumber,
        amount: _currentInvoice.totalAmount,
      );

      // Local update for immediate feedback
      setState(() {
        _currentInvoice = _currentInvoice.copyWith(approvalStatus: 'pending');
      });

      if (mounted) {
        showErpSuccess(
          context: context,
          title: 'Submitted',
          message: 'Invoice submitted for approval successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(
          context: context,
          title: 'Approval Failed',
          message: 'Could not submit invoice for approval.',
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _postToAccounting() async {
    setState(() => _isPosting = true);
    try {
      await _invoiceService.postInvoice(
        widget.user.companyId!,
        _currentInvoice,
        widget.user,
      );
      
      // Re-fetch to get updated status/flags from Firestore
      final updatedDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.user.companyId)
          .collection('salesInvoices')
          .doc(_currentInvoice.id)
          .get();
      
      if (updatedDoc.exists && mounted) {
        setState(() {
          _currentInvoice = InvoiceModel.fromMap(
            updatedDoc.data()!,
            updatedDoc.id,
          );
        });
      }

      if (mounted) {
        showErpSuccess(
          context: context,
          title: 'Posted',
          message: 'Invoice posted to accounting successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(
          context: context,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoice = _currentInvoice;

    final primaryColor = _company != null
        ? Color(
            int.parse(_company!.primaryBrandColor.replaceFirst('#', '0xFF')),
          )
        : (invoice.primaryBrandColor != null
              ? Color(
                  int.parse(
                    invoice.primaryBrandColor!.replaceFirst('#', '0xFF'),
                  ),
                )
              : theme.colorScheme.primary);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          if (!invoice.isPosted) ...[
            if (invoice.approvalStatus == 'approved' ||
                widget.user.role.hasPermission(AppPermission.manageAccounting))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _isPosting ? null : _postToAccounting,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.account_balance),
                  label: const Text('Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else if (invoice.approvalStatus == null ||
                invoice.approvalStatus == 'rejected')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _isPosting ? null : _submitForApproval,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit for Approval'),
                ),
              ),
          ],
          if (invoice.approvalStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                label: Text(
                  invoice.approvalStatus!.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: invoice.approvalStatus == 'approved'
                    ? Colors.green
                    : (invoice.approvalStatus == 'pending'
                          ? Colors.orange
                          : Colors.red),
              ),
            ),
          if (invoice.isPosted)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                label: Text(
                  'POSTED',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: Colors.blue,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              // Future print functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Future share functionality
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          margin: const EdgeInsets.all(20),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_company?.companyLogoUrl != null ||
                              invoice.companyLogoUrl != null)
                            Image.network(
                              _company?.companyLogoUrl ??
                                  invoice.companyLogoUrl!,
                              height: 60,
                            )
                          else
                            Icon(
                              Icons.account_balance_wallet,
                              size: 60,
                              color: primaryColor,
                            ),
                          const SizedBox(height: 16),
                          Text(
                            _company?.companyLegalName ?? 'LedGix ERP',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_company?.address != null)
                            Text(
                              _company!.address!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          if (_company?.trnVatNumber != null)
                            Text(
                              'TRN: ${_company!.trnVatNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'INVOICE',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '# ${invoice.invoiceNumber}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Billing Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILL TO',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              invoice.customerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // In a real app, you'd fetch customer address here
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildInfoRow(
                              context,
                              'Invoice Date',
                              DateFormat(
                                'dd MMM yyyy',
                              ).format(invoice.invoiceDate),
                            ),
                            _buildInfoRow(
                              context,
                              'Due Date',
                              DateFormat('dd MMM yyyy').format(invoice.dueDate),
                            ),
                            _buildInfoRow(
                              context,
                              'Status',
                              invoice.status.name.toUpperCase(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Items Table
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        children: [
                          _buildHeaderCell('Description'),
                          _buildHeaderCell('Qty'),
                          _buildHeaderCell(
                            'Unit Price',
                            textAlign: TextAlign.right,
                          ),
                          _buildHeaderCell('Total', textAlign: TextAlign.right),
                        ],
                      ),
                      ...invoice.items.map(
                        (item) => TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Text(item.description),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Text(item.quantity.toString()),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Text(
                                NumberFormat('#,##0.00').format(item.unitPrice),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Text(
                                NumberFormat('#,##0.00').format(item.lineTotal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Totals
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 250,
                      child: Column(
                        children: [
                          _buildTotalRow('Subtotal', invoice.subtotal),
                          _buildTotalRow('VAT Amount', invoice.vatAmount),
                          const Divider(height: 24),
                          _buildTotalRow(
                            'Total',
                            invoice.totalAmount,
                            isBold: true,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 64),
                  _buildApprovalHistory(),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Thank you for your business!',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalHistory() {
    return StreamBuilder<List<ApprovalRequestModel>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.user.companyId)
          .collection('approvalRequests')
          .where('sourceId', isEqualTo: _currentInvoice.id)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => ApprovalRequestModel.fromMap(doc.data(), doc.id))
                .toList(),
          ),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) return const SizedBox.shrink();

        final request = requests.first; // Assume one request per doc for now

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approval History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...request.history.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      h.action == ApprovalStatus.approved
                          ? Icons.check_circle
                          : (h.action == ApprovalStatus.rejected
                                ? Icons.cancel
                                : Icons.replay),
                      size: 16,
                      color: h.action == ApprovalStatus.approved
                          ? Colors.green
                          : (h.action == ApprovalStatus.rejected
                                ? Colors.red
                                : Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${h.action.name.toUpperCase()} by ${h.userName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (h.comments != null && h.comments!.isNotEmpty)
                            Text(
                              '"${h.comments}"',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          Text(
                            DateFormat('dd MMM yyyy HH:mm').format(h.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.grey),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign textAlign = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text.toUpperCase(),
        textAlign: textAlign,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            NumberFormat('#,##0.00').format(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
