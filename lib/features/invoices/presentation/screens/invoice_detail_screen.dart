import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/core/auth/permission.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final AppUser user;

  const InvoiceDetailScreen({super.key, required this.invoice, required this.user});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _postingService = AccountingPostingService();
  final _approvalService = ApprovalService();
  bool _isPosting = false;
  late InvoiceModel _currentInvoice;

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
  }

  Future<void> _submitForApproval() async {
    setState(() => _isPosting = true);
    try {
      final request = ApprovalRequestModel(
        id: '',
        companyId: widget.user.companyId!,
        sourceType: 'salesInvoice',
        sourceId: _currentInvoice.id,
        sourceNumber: _currentInvoice.invoiceNumber,
        requestedByUserId: widget.user.uid,
        requestedByUserName: widget.user.fullName,
        requestedAt: DateTime.now(),
      );

      await _approvalService.submitForApproval(request);
      
      // Update invoice locally/Firestore
      // For simplicity, we assume Firestore syncs or we refresh.
      // Let's update Firestore status for the invoice
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.user.companyId)
          .collection('salesInvoices')
          .doc(_currentInvoice.id)
          .update({'approvalStatus': 'pending'});

      setState(() {
        _currentInvoice = InvoiceModel.fromMap(_currentInvoice.toMap()..['approvalStatus'] = 'pending', _currentInvoice.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice submitted for approval')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _postToAccounting() async {
    setState(() => _isPosting = true);
    try {
      await _postingService.postSalesInvoice(widget.user.companyId!, _currentInvoice, widget.user);
      setState(() {
        _currentInvoice = InvoiceModel(
          id: _currentInvoice.id,
          companyId: _currentInvoice.companyId,
          invoiceNumber: _currentInvoice.invoiceNumber,
          customerId: _currentInvoice.customerId,
          customerName: _currentInvoice.customerName,
          invoiceDate: _currentInvoice.invoiceDate,
          dueDate: _currentInvoice.dueDate,
          status: _currentInvoice.status,
          items: _currentInvoice.items,
          subtotal: _currentInvoice.subtotal,
          vatAmount: _currentInvoice.vatAmount,
          totalAmount: _currentInvoice.totalAmount,
          balanceDue: _currentInvoice.balanceDue,
          createdAt: _currentInvoice.createdAt,
          isPosted: true,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice posted to accounting successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
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
    final primaryColor = invoice.primaryBrandColor != null 
        ? Color(int.parse(invoice.primaryBrandColor!.replaceFirst('#', '0xFF')))
        : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          if (!invoice.isPosted) ...[
            if (invoice.approvalStatus == 'approved' || widget.user.role.hasPermission(AppPermission.manageAccounting))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _isPosting ? null : _postToAccounting,
                  icon: _isPosting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.account_balance),
                  label: const Text('Post to Accounting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else if (invoice.approvalStatus == null || invoice.approvalStatus == 'rejected')
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
                  : (invoice.approvalStatus == 'pending' ? Colors.orange : Colors.red),
              ),
            ),
          if (invoice.isPosted)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Chip(
                label: Text('POSTED', style: TextStyle(color: Colors.white, fontSize: 10)),
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
          margin: const EdgeInsets.all(32),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
                          if (invoice.companyLogoUrl != null)
                            Image.network(invoice.companyLogoUrl!, height: 60)
                          else
                            Icon(Icons.account_balance_wallet, size: 60, color: primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'LedGix ERP', // Default if company name not in invoice model yet
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                            Text('BILL TO', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              invoice.customerName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            // In a real app, you'd fetch customer address here
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildInfoRow('Invoice Date', DateFormat('dd MMM yyyy').format(invoice.invoiceDate)),
                            _buildInfoRow('Due Date', DateFormat('dd MMM yyyy').format(invoice.dueDate)),
                            _buildInfoRow('Status', invoice.status.name.toUpperCase()),
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
                          border: Border(bottom: BorderSide(color: primaryColor, width: 2)),
                        ),
                        children: [
                          _buildHeaderCell('Description'),
                          _buildHeaderCell('Qty'),
                          _buildHeaderCell('Unit Price', textAlign: TextAlign.right),
                          _buildHeaderCell('Total', textAlign: TextAlign.right),
                        ],
                      ),
                      ...invoice.items.map((item) => TableRow(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(item.description),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(item.quantity.toString()),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(
                              NumberFormat('#,##0.00').format(item.unitPrice),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Text(
                              NumberFormat('#,##0.00').format(item.lineTotal),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      )),
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
                  const Divider(),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Thank you for your business!',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 13),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.grey)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTotalRow(String label, double value, {bool isBold = false, Color? color}) {
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
