import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';
import 'package:ledgixerp/features/operations/jobs/services/job_service.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/expenses/models/expense_voucher_model.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/bill_detail_screen.dart';
import 'package:ledgixerp/features/expenses/presentation/screens/expense_voucher_detail_screen.dart';
import 'package:ledgixerp/features/invoices/presentation/screens/add_invoice_screen.dart';
import 'package:ledgixerp/features/invoices/services/invoice_service.dart';
import 'package:ledgixerp/features/suppliers/presentation/screens/add_bill_screen.dart';
import 'package:ledgixerp/features/suppliers/services/bill_service.dart';
import 'package:ledgixerp/features/expenses/services/expense_voucher_service.dart';
import 'package:ledgixerp/features/expenses/presentation/screens/add_expense_voucher_screen.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  final AppUser user;

  const JobDetailScreen({super.key, required this.job, required this.user});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _jobService = JobService();
  final _invoiceService = InvoiceService();
  final _billService = BillService();
  final _expenseService = ExpenseVoucherService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profit = widget.job.actualRevenue - widget.job.actualCost;
    final profitColor = profit >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text('Job: ${widget.job.jobNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(theme, profit, profitColor),
            const SizedBox(height: 32),
            Text(
              'Job Transactions',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<dynamic>>(
              stream: _jobService.getJobTransactions(widget.user.companyId!, widget.job.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Text('No transactions linked to this job yet.'),
                    ),
                  );
                }

                return DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Reference')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: transactions.map((tx) => _buildDataRow(tx)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, double profit, Color profitColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.jobName,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Customer: ${widget.job.customerName ?? '-'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                _buildStatusChip(widget.job.status),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Total Revenue', AppFormatters.currency(widget.job.actualRevenue), Colors.blue),
                _buildSummaryItem('Total Expenses', AppFormatters.currency(widget.job.actualCost), Colors.orange),
                _buildSummaryItem('Net Profit/Loss', AppFormatters.currency(profit), profitColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  DataRow _buildDataRow(dynamic tx) {
    DateTime date;
    String type;
    String reference;
    String description;
    double amount;
    String status;
    bool isPosted;

    if (tx is InvoiceModel) {
      date = tx.invoiceDate;
      type = 'Invoice';
      reference = tx.invoiceNumber;
      description = tx.customerName;
      amount = tx.totalAmount;
      status = tx.status.name;
      isPosted = tx.isPosted;
    } else if (tx is BillModel) {
      date = tx.billDate;
      type = 'Bill';
      reference = tx.billNumber;
      description = tx.supplierName;
      amount = tx.totalAmount;
      status = tx.status.name;
      isPosted = tx.isPosted;
    } else if (tx is ExpenseVoucherModel) {
      date = tx.date;
      type = 'Expense';
      reference = tx.voucherNumber;
      description = tx.description;
      amount = tx.totalAmount;
      status = tx.status.name;
      isPosted = tx.status == ExpenseVoucherStatus.posted;
    } else {
      return const DataRow(cells: []);
    }

    return DataRow(
      cells: [
        DataCell(Text(DateFormat('dd/MM/yyyy').format(date))),
        DataCell(Text(type)),
        DataCell(Text(reference)),
        DataCell(Text(description)),
        DataCell(Text(AppFormatters.currency(amount))),
        DataCell(Text(status.toUpperCase())),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _viewTransaction(tx),
                tooltip: 'View',
              ),
              if (!isPosted) ...[
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editTransaction(tx),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteTransaction(tx),
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _viewTransaction(dynamic tx) {
    if (tx is InvoiceModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceDetailScreen(invoice: tx, user: widget.user),
        ),
      );
    } else if (tx is BillModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillDetailScreen(bill: tx, user: widget.user),
        ),
      );
    } else if (tx is ExpenseVoucherModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExpenseVoucherDetailScreen(voucher: tx, user: widget.user),
        ),
      );
    }
  }

  void _editTransaction(dynamic tx) {
    if (tx is InvoiceModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddInvoiceScreen(user: widget.user, initialInvoice: tx),
        ),
      );
    } else if (tx is BillModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddBillScreen(user: widget.user, initialBill: tx),
        ),
      );
    } else if (tx is ExpenseVoucherModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseVoucherScreen(user: widget.user, initialVoucher: tx),
        ),
      );
    } else {
      showErpSuccess(context: context, title: 'Coming Soon', message: 'Editing functionality for this type is coming soon.');
    }
  }

  Future<void> _deleteTransaction(dynamic tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this transaction? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (tx is InvoiceModel) {
          await _invoiceService.deleteInvoice(widget.user.companyId!, tx.id);
        } else if (tx is BillModel) {
          await _billService.deleteBill(widget.user.companyId!, tx.id);
        } else if (tx is ExpenseVoucherModel) {
          await _expenseService.deleteVoucher(widget.user.companyId!, tx.id);
        }
        if (mounted) showErpSuccess(context: context, title: 'Success', message: 'Transaction deleted successfully.');
      } catch (e) {
        if (mounted) showErpError(context: context, error: e);
      }
    }
  }

  Widget _buildStatusChip(JobStatus status) {
    Color color;
    switch (status) {
      case JobStatus.draft: color = Colors.grey; break;
      case JobStatus.active: color = Colors.green; break;
      case JobStatus.completed: color = Colors.blue; break;
      case JobStatus.cancelled: color = Colors.red; break;
    }
    return Chip(
      label: Text(status.label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: color,
    );
  }
}
