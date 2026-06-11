import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/expenses/models/expense_voucher_model.dart';
import 'package:ledgixerp/features/expenses/services/expense_voucher_service.dart';
import 'package:ledgixerp/features/expenses/presentation/screens/add_expense_voucher_screen.dart';
import 'package:ledgixerp/features/expenses/presentation/screens/expense_voucher_detail_screen.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';

class ExpenseVouchersScreen extends StatefulWidget {
  final AppUser user;

  const ExpenseVouchersScreen({super.key, required this.user});

  @override
  State<ExpenseVouchersScreen> createState() => _ExpenseVouchersScreenState();
}

class _ExpenseVouchersScreenState extends State<ExpenseVouchersScreen> {
  final _service = ExpenseVoucherService();

  @override
  Widget build(BuildContext context) {
    return VoucherListPage<ExpenseVoucherModel>(
      title: 'Expense Vouchers',
      subtitle: 'Manage and track your direct cash/bank expenses',
      stream: _service.getVouchers(widget.user.companyId!),
      onAddNew: () {
        SidePanel.show(
          context: context,
          title: 'New Expense Voucher',
          child: AddExpenseVoucherScreen(user: widget.user, isPane: true),
        );
      },
      columns: const ['Voucher #', 'Description', 'Date', 'Amount', 'Status', 'Actions'],
      emptyTitle: 'No expense vouchers found',
      emptyMessage: 'Start by recording your first expense voucher.',
      rowBuilder: (voucher, index) {
        return DataRow(
          cells: [
            DataCell(Text(voucher.voucherNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(voucher.description)),
            DataCell(Text(AppFormatters.date(voucher.date))),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppFormatters.currency(voucher.totalAmount + voucher.totalVat),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(ERPStatusBadge.fromStatus(voucher.status.name)),
            DataCell(
              VoucherActionMenu(
                onView: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpenseVoucherDetailScreen(
                        voucher: voucher,
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
                    builder: (context) => ERPConfirmDeleteDialog(
                      title: 'Delete Voucher',
                      message: 'Are you sure you want to delete voucher ${voucher.voucherNumber}?',
                      onConfirm: () async {
                        // try {
                        //   await _service.deleteVoucher(widget.user.companyId!, voucher.id);
                        // } catch (e) {
                        //   if (mounted) showErpError(context: context, error: e);
                        // }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delete not implemented for Expense Vouchers yet.')),
                        );
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
