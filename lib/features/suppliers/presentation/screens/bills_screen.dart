import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/suppliers/services/bill_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/add_bill_screen.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/core/widgets/attachment_viewer.dart';

import 'package:ledgixerp/widgets/erp_ui_components.dart';

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

  Future<void> _submitForApproval(BillModel bill) async {
    try {
      final request = ApprovalRequestModel(
        id: '',
        companyId: widget.user.companyId!,
        sourceType: 'supplierBill',
        sourceId: bill.id,
        sourceNumber: bill.billNumber,
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

  Future<void> _postToAccounting(BillModel bill) async {
    // Basic check - In real app, only Approved bills can be posted
    // Unless user has manageAccounting permission
    bool isApproved = bill.status == BillStatus.approved;
    bool canBypass = widget.user.role.hasPermission(
      AppPermission.manageAccounting,
    );

    if (!isApproved && !canBypass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill must be approved before posting')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill posted to accounting successfully'),
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
    final canManage = widget.user.role.hasPermission(AppPermission.manageBills);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Invoices (Bills)'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  showErpSidePane(
                    context: context,
                    builder: AddBillScreen(
                      user: widget.user,
                      isPane: true,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<BillModel>>(
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bills found',
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
                      'Bill #',
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
                      'Reference',
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
                      'Due Date',
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
                rows: bills.map((bill) {
                  return DataRow(
                    cells: [
                      DataCell(Text(bill.billNumber)),
                      DataCell(Text(bill.supplierName)),
                      DataCell(Text(bill.reference ?? '-')),
                      DataCell(
                        Text(DateFormat('dd MMM yyyy').format(bill.billDate)),
                      ),
                      DataCell(
                        Text(DateFormat('dd MMM yyyy').format(bill.dueDate)),
                      ),
                      DataCell(
                        Text(NumberFormat('#,##0.00').format(bill.totalAmount)),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              bill.status,
                              bill.isPosted,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            bill.isPosted
                                ? 'POSTED'
                                : bill.status.name.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(
                                bill.status,
                                bill.isPosted,
                              ),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            if (!bill.isPosted &&
                                bill.status == BillStatus.draft)
                              TextButton(
                                onPressed: () => _submitForApproval(bill),
                                child: const Text(
                                  'Submit',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            if (!bill.isPosted &&
                                (bill.status == BillStatus.approved ||
                                    widget.user.role.hasPermission(
                                      AppPermission.manageAccounting,
                                    )))
                              IconButton(
                                icon: const Icon(
                                  Icons.account_balance,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Post to Accounting',
                                onPressed: () => _postToAccounting(bill),
                              ),
                            if (bill.isPosted)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                                size: 20,
                              ),
                            if (bill.attachments.isNotEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.attach_file,
                                  size: 20,
                                  color: Colors.blueGrey,
                                ),
                                tooltip: 'View Attachments',
                                onPressed:
                                    () => showAttachmentDialog(
                                      context,
                                      bill.attachments,
                                    ),
                              ),
                          ],
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
}
