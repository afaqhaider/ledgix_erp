import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/app_user.dart';
import '../../../../core/widgets/side_panel.dart';
import '../../models/expense_voucher_model.dart';
import '../../services/expense_voucher_service.dart';
import 'add_expense_voucher_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Vouchers'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _openAddVoucher(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Voucher'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<ExpenseVoucherModel>>(
        stream: _service.getVouchers(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final vouchers = snapshot.data ?? [];
          if (vouchers.isEmpty) {
            return const Center(child: Text('No expense vouchers found.'));
          }

          return ListView.builder(
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              return ListTile(
                title: Text(voucher.voucherNumber),
                subtitle: Text(voucher.description),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(voucher.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      (voucher.totalAmount + voucher.totalVat).toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                onTap: () {
                  // View Details
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openAddVoucher(BuildContext context) {
    SidePanel.show(
      context: context,
      title: 'New Expense Voucher',
      child: AddExpenseVoucherScreen(user: widget.user, isPane: true),
    );
  }
}
