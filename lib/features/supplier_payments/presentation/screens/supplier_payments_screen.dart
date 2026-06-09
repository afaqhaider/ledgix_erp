import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/services/supplier_payment_service.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/features/supplier_payments/presentation/screens/add_supplier_payment_screen.dart';

import 'package:google_fonts/google_fonts.dart';

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
      await _approvalService.submitForApproval(
        user: widget.user,
        companyId: widget.user.companyId!,
        sourceType: 'supplier_payment',
        sourceId: payment.id,
        sourceNumber: payment.paymentNumber,
        amount: payment.amount,
      );

      if (mounted) {
        showErpSuccess(
          context: context,
          title: 'Success',
          message: 'Payment submitted for approval successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    }
  }

  Future<void> _postToAccounting(SupplierPaymentModel payment) async {
    // Check approval
    if (payment.approvalStatus != 'approved' &&
        !widget.user.role.hasPermission(AppPermission.manageAccounting)) {
      showErpError(
        context: context,
        title: 'Approval Required',
        message:
            'This payment must be approved before it can be posted to the ledger.',
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
        showErpSuccess(
          context: context,
          title: 'Posted',
          message: 'Payment posted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canManage =
        widget.user.role.hasPermission(AppPermission.manageSuppliers) ||
        widget.user.role.hasPermission(AppPermission.manageAccounting);
    final isAdmin = widget.user.role.hasPermission(
      AppPermission.manageAccounting,
    );

    return Column(
      children: [
        _buildHeader(theme, canManage),
        Expanded(
          child: StreamBuilder<List<SupplierPaymentModel>>(
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
                return _buildEmptyState(theme);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 52,
                        horizontalMargin: 24,
                        columnSpacing: 32,
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                        ),
                        columns: [
                          _buildColumn('Payment #'),
                          _buildColumn('Supplier'),
                          _buildColumn('Date'),
                          _buildColumn('Amount', numeric: true),
                          _buildColumn('Method'),
                          _buildColumn('Approval'),
                          _buildColumn('Actions'),
                        ],
                        rows: payments.map((payment) {
                          final isApproved =
                              payment.approvalStatus == 'approved';
                          final canEdit = canManage && !payment.isPosted;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  payment.paymentNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  payment.supplierName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.date(payment.paymentDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  AppFormatters.currency(
                                    payment.amount,
                                    symbol: _company?.baseCurrency,
                                  ),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  payment.paymentMethod.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(_buildApprovalBadge(payment)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      tooltip: 'View',
                                      onPressed: () =>
                                          _showPaymentDetails(payment),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (canEdit)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        tooltip: 'Edit',
                                        onPressed: _showEditUnavailable,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    payment.isPosted
                                        ? const Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: Colors.blue,
                                            size: 18,
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.account_balance,
                                              size: 18,
                                            ),
                                            color: (isApproved || isAdmin)
                                                ? Colors.orange
                                                : Colors.grey,
                                            tooltip: 'Post to Accounting',
                                            onPressed: (isApproved || isAdmin)
                                                ? () =>
                                                      _postToAccounting(payment)
                                                : null,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                    if (canManage && !payment.isPosted)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed: () =>
                                            _confirmDelete(payment),
                                        visualDensity: VisualDensity.compact,
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool canManage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier Payments',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage and track payments made to your suppliers',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (canManage)
            ElevatedButton.icon(
              onPressed: () {
                SidePanel.show(
                  context: context,
                  title: 'Add Supplier Payment',
                  child: AddSupplierPaymentScreen(user: widget.user),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(SupplierPaymentModel payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text(
          'Are you sure you want to delete payment ${payment.paymentNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _paymentService.deletePayment(widget.user.companyId!, payment.id);
      if (mounted) {
        showErpSuccess(
          context: context,
          title: 'Deleted',
          message: 'Payment deleted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    }
  }

  void _showPaymentDetails(SupplierPaymentModel payment) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment ${payment.paymentNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supplier: ${payment.supplierName}'),
            Text('Date: ${AppFormatters.date(payment.paymentDate)}'),
            Text(
              'Amount: ${AppFormatters.currency(payment.amount, symbol: _company?.baseCurrency)}',
            ),
            Text('Method: ${payment.paymentMethod.name.toUpperCase()}'),
            Text('Status: ${payment.isPosted ? 'Posted' : 'Draft'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit screen for saved payments is not wired yet.'),
      ),
    );
  }

  DataColumn _buildColumn(String label, {bool numeric = false}) {
    return DataColumn(
      numeric: numeric,
      label: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildApprovalBadge(SupplierPaymentModel payment) {
    if (payment.approvalStatus == null) {
      return TextButton(
        onPressed: () => _submitForApproval(payment),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Submit', style: TextStyle(fontSize: 12)),
      );
    }

    final color = _getApprovalStatusColor(payment.approvalStatus!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        payment.approvalStatus!.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No supplier payments found',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
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
