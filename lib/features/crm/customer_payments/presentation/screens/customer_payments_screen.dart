import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/services/customer_payment_service.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/features/crm/customer_payments/presentation/screens/add_customer_payment_screen.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';

class CustomerPaymentsScreen extends StatefulWidget {
  final AppUser user;
  const CustomerPaymentsScreen({super.key, required this.user});

  @override
  State<CustomerPaymentsScreen> createState() => _CustomerPaymentsScreenState();
}

class _CustomerPaymentsScreenState extends State<CustomerPaymentsScreen> {
  final _paymentService = CustomerPaymentService();
  // ignore: unused_field
  final _postingService = AccountingPostingService();

  @override
  Widget build(BuildContext context) {
    return VoucherListPage<CustomerPaymentModel>(
      title: 'Customer Receipts',
      subtitle: 'Track and manage customer payments and receipts',
      stream: _paymentService.getPayments(widget.user.companyId!),
      onAddNew: () {
        SidePanel.show(
          context: context,
          title: 'Add New Receipt',
          child: AddCustomerPaymentScreen(user: widget.user),
        );
      },
      columns: const [
        'Receipt #',
        'Customer',
        'Date',
        'Amount',
        'Status',
        'Method',
        'Actions'
      ],
      emptyTitle: 'No receipts found',
      emptyMessage: 'Start by recording your first customer payment.',
      rowBuilder: (payment, index) {
        return DataRow(
          cells: [
            DataCell(Text(payment.paymentNumber,
                style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(payment.customerName)),
            DataCell(Text(AppFormatters.date(payment.paymentDate))),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppFormatters.currency(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(ERPStatusBadge.fromStatus(
                payment.isPosted ? 'POSTED' : (payment.approvalStatus ?? 'DRAFT'))),
            DataCell(Text(payment.paymentMethod.name.toUpperCase())),
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
                      title: 'Delete Receipt',
                      message:
                          'Are you sure you want to delete receipt ${payment.paymentNumber}?',
                      onConfirm: () async {
                        try {
                          await _paymentService.deletePayment(
                              widget.user.companyId!, payment.id);
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
