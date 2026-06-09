import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/suppliers/services/bill_service.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/add_bill_screen.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/core/widgets/attachment_viewer.dart';
import 'package:google_fonts/google_fonts.dart';

class BillsScreen extends StatefulWidget {
  final AppUser user;
  const BillsScreen({super.key, required this.user});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _billService = BillService();
  final _approvalService = ApprovalService();
  final _postingService = AccountingPostingService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canManage = widget.user.role.hasPermission(AppPermission.manageBills);

    return Column(
      children: [
        _buildHeader(theme, canManage),
        Expanded(
          child: StreamBuilder<List<BillModel>>(
            stream: _billService.getBills(widget.user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final bills = snapshot.data ?? [];

              if (bills.isEmpty) {
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
                          _buildColumn('Bill #'),
                          _buildColumn('Supplier'),
                          _buildColumn('Date'),
                          _buildColumn('Due Date'),
                          _buildColumn('Total', numeric: true),
                          _buildColumn('Status'),
                          _buildColumn('Actions'),
                        ],
                        rows: bills.map((bill) {
                          final canEdit = canManage && !bill.isPosted;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  bill.billNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  bill.supplierName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              DataCell(
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(bill.billDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(bill.dueDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  NumberFormat(
                                    '#,##0.00',
                                  ).format(bill.totalAmount),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusBadge(bill)),
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
                                      onPressed: () => _showBillDetails(bill),
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
                                    if (!bill.isPosted &&
                                        bill.status == BillStatus.draft)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.send_rounded,
                                          size: 18,
                                        ),
                                        tooltip: 'Submit',
                                        onPressed: () =>
                                            _submitForApproval(bill),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    if (!bill.isPosted &&
                                        (bill.status == BillStatus.approved ||
                                            widget.user.role.hasPermission(
                                              AppPermission.manageAccounting,
                                            )))
                                      IconButton(
                                        icon: const Icon(
                                          Icons.account_balance,
                                          size: 18,
                                          color: Colors.orange,
                                        ),
                                        tooltip: 'Post',
                                        onPressed: () =>
                                            _postToAccounting(bill),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    if (bill.isPosted)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                      ),
                                    if (bill.attachments.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.attach_file,
                                          size: 18,
                                          color: Colors.blueGrey,
                                        ),
                                        tooltip: 'View Attachments',
                                        onPressed: () => showAttachmentDialog(
                                          context,
                                          bill.attachments,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    if (canManage && !bill.isPosted)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed: () => _confirmDelete(bill),
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
                  'Purchase Bills',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage and track your vendor expenses',
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
                showErpSidePane(
                  context: context,
                  builder: AddBillScreen(user: widget.user, isPane: true),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Bill'),
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

  Widget _buildStatusBadge(BillModel bill) {
    final color = _getStatusColor(bill.status, bill.isPosted);
    final text = bill.isPosted ? 'POSTED' : bill.status.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
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
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No bills found',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BillStatus status, bool isPosted) {
    if (isPosted) return Colors.blue;
    switch (status) {
      case BillStatus.approved:
        return Colors.green;
      case BillStatus.pendingApproval:
        return Colors.orange;
      case BillStatus.paid:
        return Colors.blue;
      case BillStatus.voided:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitForApproval(BillModel bill) async {
    try {
      await _approvalService.submitForApproval(
        user: widget.user,
        companyId: widget.user.companyId!,
        sourceType: 'supplier_bill',
        sourceId: bill.id,
        sourceNumber: bill.billNumber,
        amount: bill.totalAmount,
      );

      if (mounted) {
        showErpSuccess(
          context: context,
          title: 'Submitted',
          message: 'Bill has been submitted for approval.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    }
  }

  Future<void> _postToAccounting(BillModel bill) async {
    bool isApproved = bill.status == BillStatus.approved;
    bool canBypass = widget.user.role.hasPermission(
      AppPermission.manageAccounting,
    );

    if (!isApproved && !canBypass) {
      showErpError(
        context: context,
        title: 'Approval Required',
        message:
            'This bill must be approved before it can be posted to the ledger.',
      );
      return;
    }

    try {
      await _postingService.postSupplierBill(
        widget.user.companyId!,
        bill,
        widget.user,
      );
      if (mounted) {
        showErpSuccess(
          context: context,
          title: 'Posted',
          message: 'Bill posted to accounting successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    }
  }

  Future<void> _confirmDelete(BillModel bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text(
          'Are you sure you want to delete bill ${bill.billNumber}?',
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
      await _billService.deleteBill(widget.user.companyId!, bill.id);
      if (mounted) {
        showErpSuccess(
          context: context,
          title: 'Deleted',
          message: 'Bill deleted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    }
  }

  void _showBillDetails(BillModel bill) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bill ${bill.billNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supplier: ${bill.supplierName}'),
            Text('Date: ${DateFormat('dd MMM yyyy').format(bill.billDate)}'),
            Text('Due: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}'),
            Text('Total: ${NumberFormat('#,##0.00').format(bill.totalAmount)}'),
            Text('Status: ${bill.isPosted ? 'Posted' : bill.status.name}'),
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
        content: Text('Edit screen for saved bills is not wired yet.'),
      ),
    );
  }
}
