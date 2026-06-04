import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/invoices/services/invoice_service.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/add_invoice_screen.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/invoice_detail_screen.dart';

import 'package:ledgixerp/widgets/erp_ui_components.dart';

class InvoicesScreen extends StatefulWidget {
  final AppUser user;
  const InvoicesScreen({super.key, required this.user});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _invoiceService = InvoiceService();
  final _companyService = CompanyService();
  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  void _loadCompany() {
    _companyService.getCompany(widget.user.companyId!).listen((company) {
      if (mounted) setState(() => _company = company);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageInvoices,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoices'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  showErpSidePane(
                    context: context,
                    builder: AddInvoiceScreen(user: widget.user, isPane: true),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<InvoiceModel>>(
        stream: _invoiceService.getInvoices(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No invoices found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topLeft,
              child: Card(
                child: DataTable(
                horizontalMargin: 24,
                columnSpacing: 40,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Invoice #',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Customer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: invoices.map((invoice) {
                  return DataRow(
                    cells: [
                      DataCell(Text(invoice.invoiceNumber)),
                      DataCell(Text(invoice.customerName)),
                      DataCell(Text(AppFormatters.date(invoice.invoiceDate))),
                      DataCell(
                        Text(
                          AppFormatters.currency(
                            invoice.totalAmount,
                            symbol: _company?.baseCurrency,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (invoice.isPosted
                                        ? Colors.green
                                        : _getStatusColor(invoice.status))
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (invoice.isPosted
                                ? 'POSTED'
                                : invoice.status.name.toUpperCase()),
                            style: TextStyle(
                              color: invoice.isPosted
                                  ? Colors.green
                                  : _getStatusColor(invoice.status),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InvoiceDetailScreen(
                                      invoice: invoice,
                                      user: widget.user,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (canManage && !invoice.isPosted)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(invoice),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Future<void> _confirmDelete(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _invoiceService.deleteInvoice(widget.user.companyId!, invoice.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.partiallyPaid:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }
}
