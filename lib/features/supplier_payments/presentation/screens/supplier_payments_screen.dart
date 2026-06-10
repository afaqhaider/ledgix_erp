import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/services/supplier_payment_service.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/features/supplier_payments/presentation/screens/add_supplier_payment_screen.dart';

class SupplierPaymentsScreen extends StatefulWidget {
  final AppUser user;
  const SupplierPaymentsScreen({super.key, required this.user});

  @override
  State<SupplierPaymentsScreen> createState() => _SupplierPaymentsScreenState();
}

class _SupplierPaymentsScreenState extends State<SupplierPaymentsScreen> {
  final _paymentService = SupplierPaymentService();

  @override
  Widget build(BuildContext context) {
    return VoucherListPage<SupplierPaymentModel>(
      title: 'Supplier Payments',
      subtitle: 'Manage and track payments made to your suppliers',
      stream: _paymentService.getPayments(widget.user.companyId!),
      onAddNew: () {
        SidePanel.show(
          context: context,
          title: 'Add Supplier Payment',
          child: AddSupplierPaymentScreen(user: widget.user),
        );
      },
      columns: const [
        'Payment #',
        'Supplier',
        'Date',
        'Amount',
        'Status',
        'Method',
        'Actions'
      ],
      emptyTitle: 'No supplier payments found',
      emptyMessage: 'Start by recording your first supplier payment.',
      rowBuilder: (payment, index) {
        return DataRow(
          cells: [
            DataCell(Text(payment.paymentNumber,
                style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(payment.supplierName)),
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
                      title: 'Delete Payment',
                      message:
                          'Are you sure you want to delete payment ${payment.paymentNumber}?',
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
