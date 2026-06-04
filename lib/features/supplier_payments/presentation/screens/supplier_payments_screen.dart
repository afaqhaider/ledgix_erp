import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/services/supplier_payment_service.dart';
import 'package:ledgixerp/features/supplier_payments/presentation/screens/add_supplier_payment_screen.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';

import 'package:ledgixerp/widgets/erp_ui_components.dart';

class SupplierPaymentsScreen extends StatefulWidget {
  final AppUser user;
  const SupplierPaymentsScreen({super.key, required this.user});

  @override
  State<SupplierPaymentsScreen> createState() => _SupplierPaymentsScreenState();
}

class _SupplierPaymentsScreenState extends State<SupplierPaymentsScreen> {
  final _paymentService = SupplierPaymentService();
  final _postingService = AccountingPostingService();
  final _approvalService = ApprovalService();
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

  Future<void> _submitForApproval(SupplierPaymentModel payment) async {
    try {
      final request = ApprovalRequestModel(
        id: '',
        companyId: widget.user.companyId!,
        sourceType: 'supplierPayment',
        sourceId: payment.id,
        sourceNumber: payment.paymentNumber,
        requestedByUserId: widget.user.uid,
        requestedByUserName: widget.user.fullName,
        requestedAt: DateTime.now(),
      );

      await _approvalService.submitForApproval(
        request,
        requesterRole: widget.user.role,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing approval/submission...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _postToAccounting(SupplierPaymentModel payment) async {
    // Check approval
    if (payment.approvalStatus != 'approved' &&
        !widget.user.role.hasPermission(AppPermission.manageAccounting)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment must be approved before posting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _postingService.postSupplierPayment(
        widget.user.companyId!,
        payment,
        widget.user,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment posted successfully'),
            backgroundColor: Colors.green,
          ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage =
        widget.user.role.hasPermission(AppPermission.manageSuppliers) ||
        widget.user.role.hasPermission(AppPermission.manageAccounting);
    final isAdmin = widget.user.role.hasPermission(
      AppPermission.manageAccounting,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Payments'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  showErpSidePane(
                    context: context,
                    builder: AddSupplierPaymentScreen(
                      user: widget.user,
                      isPane: true,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<SupplierPaymentModel>>(
        stream: _paymentService.getPayments(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final payments = snapshot.data ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No supplier payments found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: DataTable(
                horizontalMargin: 24,
                columnSpacing: 32,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Payment #',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Supplier',
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
                      'Amount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Method',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Approval',
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
                rows: payments.map((payment) {
                  final isApproved = payment.approvalStatus == 'approved';
                  return DataRow(
                    cells: [
                      DataCell(Text(payment.paymentNumber)),
                      DataCell(Text(payment.supplierName)),
                      DataCell(
                        Text(
                          AppFormatters.date(payment.paymentDate),
                        ),
                      ),
                      DataCell(
                        Text(AppFormatters.currency(payment.amount, symbol: _company?.baseCurrency)),
                      ),
                      DataCell(Text(payment.paymentMethod.name.toUpperCase())),
                      DataCell(
                        payment.approvalStatus == null
                            ? TextButton(
                                onPressed: () => _submitForApproval(payment),
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(fontSize: 12),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getApprovalStatusColor(
                                    payment.approvalStatus!,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  payment.approvalStatus!.toUpperCase(),
                                  style: TextStyle(
                                    color: _getApprovalStatusColor(
                                      payment.approvalStatus!,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      DataCell(
                        payment.isPosted
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 20,
                              )
                            : IconButton(
                                icon: const Icon(
                                  Icons.account_balance,
                                  size: 20,
                                ),
                                color: (isApproved || isAdmin)
                                    ? Colors.orange
                                    : Colors.grey,
                                tooltip: 'Post to Accounting',
                                onPressed: (isApproved || isAdmin)
                                    ? () => _postToAccounting(payment)
                                    : null,
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getApprovalStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
