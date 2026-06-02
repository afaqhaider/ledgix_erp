import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/services/customer_payment_service.dart';
import 'package:ledgixerp/features/crm/customer_payments/presentation/screens/add_customer_payment_screen.dart';
import 'package:ledgixerp/features/accounting/journal_entries/accounting_posting_service.dart';
import 'package:ledgixerp/features/approvals/models/approval_request_model.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPaymentsScreen extends StatefulWidget {
  final AppUser user;
  const CustomerPaymentsScreen({super.key, required this.user});

  @override
  State<CustomerPaymentsScreen> createState() => _CustomerPaymentsScreenState();
}

class _CustomerPaymentsScreenState extends State<CustomerPaymentsScreen> {
  final _paymentService = CustomerPaymentService();
  final _postingService = AccountingPostingService();
  final _approvalService = ApprovalService();

  Future<void> _submitForApproval(CustomerPaymentModel payment) async {
    try {
      final request = ApprovalRequestModel(
        id: '',
        companyId: widget.user.companyId!,
        sourceType: 'customerPayment', // We need to handle this in ApprovalService
        sourceId: payment.id,
        sourceNumber: payment.paymentNumber,
        requestedByUserId: widget.user.uid,
        requestedByUserName: widget.user.fullName,
        requestedAt: DateTime.now(),
      );

      await _approvalService.submitForApproval(request);
      
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.user.companyId)
          .collection('customerPayments')
          .doc(payment.id)
          .update({'approvalStatus': 'pending'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment submitted for approval')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _postToAccounting(CustomerPaymentModel payment) async {
    // Check approval
    if (payment.approvalStatus != 'approved' && 
        !widget.user.role.hasPermission(AppPermission.manageAccounting)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment must be approved before posting'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      await _postingService.postCustomerPayment(widget.user.companyId!, payment, widget.user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment posted successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = widget.user.role.hasPermission(AppPermission.manageInvoices) || 
                      widget.user.role.hasPermission(AppPermission.manageAccounting);
    final isAdmin = widget.user.role.hasPermission(AppPermission.manageAccounting);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Payments'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCustomerPaymentScreen(user: widget.user),
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
      body: StreamBuilder<List<CustomerPaymentModel>>(
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
                  Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No customer payments found',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
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
                  DataColumn(label: Text('Payment #', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Method', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Approval', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: payments.map((payment) {
                  final isApproved = payment.approvalStatus == 'approved';
                  return DataRow(
                    cells: [
                      DataCell(Text(payment.paymentNumber)),
                      DataCell(Text(payment.customerName)),
                      DataCell(Text(DateFormat('dd MMM yyyy').format(payment.paymentDate))),
                      DataCell(Text(NumberFormat('#,##0.00').format(payment.amount))),
                      DataCell(Text(payment.paymentMethod.name.toUpperCase())),
                      DataCell(
                        payment.approvalStatus == null 
                          ? TextButton(
                              onPressed: () => _submitForApproval(payment),
                              child: const Text('Submit', style: TextStyle(fontSize: 12)),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getApprovalStatusColor(payment.approvalStatus!).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payment.approvalStatus!.toUpperCase(),
                                style: TextStyle(
                                  color: _getApprovalStatusColor(payment.approvalStatus!),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                      ),
                      DataCell(
                        payment.isPosted
                          ? const Icon(Icons.check_circle, color: Colors.blue, size: 20)
                          : IconButton(
                              icon: const Icon(Icons.account_balance, size: 20),
                              color: (isApproved || isAdmin) ? Colors.orange : Colors.grey,
                              tooltip: 'Post to Accounting',
                              onPressed: (isApproved || isAdmin) ? () => _postToAccounting(payment) : null,
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
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }
}
