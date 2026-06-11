import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/suppliers/services/bill_service.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/add_bill_screen.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

import 'package:ledgixerp/features/suppliers/presentation/screens/bill_detail_screen.dart';

class BillsScreen extends StatefulWidget {
  final AppUser user;
  const BillsScreen({super.key, required this.user});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _billService = BillService();

  @override
  Widget build(BuildContext context) {
    return VoucherListPage<BillModel>(
      title: 'Supplier Bills',
      subtitle: 'Manage and track your vendor expenses',
      stream: _billService.getBills(widget.user.companyId!),
      onAddNew: () {
        showErpSidePane(
          context: context,
          builder: AddBillScreen(user: widget.user, isPane: true),
        );
      },
      columns: const ['Bill #', 'Supplier', 'Date', 'Due Date', 'Total', 'Status', 'Actions'],
      emptyTitle: 'No bills found',
      emptyMessage: 'Start by recording your first vendor bill.',
      rowBuilder: (bill, index) {
        return DataRow(
          cells: [
            DataCell(Text(bill.billNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(bill.supplierName)),
            DataCell(Text(AppFormatters.date(bill.billDate))),
            DataCell(Text(AppFormatters.date(bill.dueDate))),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppFormatters.currency(bill.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(ERPStatusBadge.fromStatus(bill.isPosted ? 'POSTED' : bill.status.name)),
            DataCell(
              VoucherActionMenu(
                onView: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillDetailScreen(
                        bill: bill,
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
                      title: 'Delete Bill',
                      message: 'Are you sure you want to delete bill ${bill.billNumber}?',
                      onConfirm: () async {
                        try {
                          await _billService.deleteBill(widget.user.companyId!, bill.id);
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
