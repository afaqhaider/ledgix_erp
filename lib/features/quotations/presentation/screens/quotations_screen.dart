import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/quotations/services/quotation_service.dart';
import 'package:ledgixerp/features/quotations/presentation/screens/add_quotation_screen.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class QuotationsScreen extends StatefulWidget {
  final AppUser user;
  const QuotationsScreen({super.key, required this.user});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final _quotationService = QuotationService();

  @override
  Widget build(BuildContext context) {
    return VoucherListPage<QuotationModel>(
      title: 'Sales Quotations',
      subtitle: 'Generate and manage professional quotes for clients',
      stream: _quotationService.getQuotations(widget.user.companyId!),
      onAddNew: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddQuotationScreen(user: widget.user),
          ),
        );
      },
      columns: const ['Quotation #', 'Customer', 'Date', 'Total', 'Status', 'Actions'],
      emptyTitle: 'No quotations found',
      emptyMessage: 'Start by creating your first sales quotation.',
      rowBuilder: (quo, index) {
        return DataRow(
          cells: [
            DataCell(Text(quo.quotationNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(quo.customerName)),
            DataCell(Text(AppFormatters.date(quo.quotationDate))),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppFormatters.currency(quo.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(ERPStatusBadge.fromStatus(quo.status.name)),
            DataCell(
              VoucherActionMenu(
                onView: () {
                   // Show details
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
                      title: 'Delete Quotation',
                      message: 'Are you sure you want to delete quotation ${quo.quotationNumber}?',
                      onConfirm: () async {
                        try {
                          await _quotationService.deleteQuotation(widget.user.companyId!, quo.id);
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
