import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/add_account_dialog.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  final AppUser user;
  const ChartOfAccountsScreen({super.key, required this.user});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final _accountService = AccountService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = widget.user.role.hasPermission(AppPermission.manageAccounting);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart of Accounts'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddAccountDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<AccountModel>>(
        stream: _accountService.getAccounts(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final accounts = snapshot.data ?? [];

          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts found',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _showAddAccountDialog(context),
                      child: const Text('Add Your First Account'),
                    ),
                  ],
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: DataTable(
                  horizontalMargin: 24,
                  columnSpacing: 40,
                  columns: const [
                    DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: accounts.map((account) {
                    return DataRow(
                      cells: [
                        DataCell(Text(account.accountCode)),
                        DataCell(Text(account.accountName)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(account.accountType).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              account.accountType.label,
                              style: TextStyle(
                                color: _getTypeColor(account.accountType),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Icon(
                            account.isActive ? Icons.check_circle : Icons.cancel,
                            color: account.isActive ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: canManage ? () {} : null,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTypeColor(AccountType type) {
    switch (type) {
      case AccountType.asset: return Colors.blue;
      case AccountType.liability: return Colors.orange;
      case AccountType.equity: return Colors.purple;
      case AccountType.income: return Colors.green;
      case AccountType.costOfSales: return Colors.deepOrange;
      case AccountType.expense: return Colors.red;
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(companyId: widget.user.companyId!),
    );
  }
}
