import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/invoices/services/invoice_service.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/add_invoice_screen.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class InvoicesScreen extends StatefulWidget {
  final AppUser user;
  const InvoicesScreen({super.key, required this.user});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _invoiceService = InvoiceService();

  @override
  Widget build(BuildContext context) {
    return VoucherListPage<InvoiceModel>(
      title: 'Sales Invoices',
      subtitle: 'Manage and track your customer billings',
      stream: _invoiceService.getInvoices(widget.user.companyId!),
      onAddNew: () {
        showErpSidePane(
          context: context,
          builder: AddInvoiceScreen(user: widget.user, isPane: true),
        );
      },
      columns: const ['Invoice #', 'Customer', 'Date', 'Total', 'Status', 'Actions'],
      emptyTitle: 'No invoices found',
      emptyMessage: 'Start by creating your first sales invoice.',
      rowBuilder: (invoice, index) {
        return DataRow(
          cells: [
            DataCell(Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(invoice.customerName)),
            DataCell(Text(AppFormatters.date(invoice.invoiceDate))),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppFormatters.currency(invoice.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(ERPStatusBadge.fromStatus(invoice.isPosted ? 'POSTED' : invoice.status.name)),
            DataCell(
              VoucherActionMenu(
                onView: () {
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
                onEdit: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit screen not wired yet.')),
                  );
                },
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (_) => ERPConfirmDeleteDialog(
                      title: 'Delete Invoice',
                      message: 'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
                      onConfirm: () async {
                        try {
                          await _invoiceService.deleteInvoice(widget.user.companyId!, invoice.id);
                        } catch (e) {
                          if (context.mounted) showErpError(context: context, error: e);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
