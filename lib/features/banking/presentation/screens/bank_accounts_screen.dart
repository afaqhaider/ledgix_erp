import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/services/bank_account_service.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/features/banking/presentation/widgets/add_bank_account_dialog.dart';

class BankAccountsScreen extends StatefulWidget {
  final AppUser user;
  const BankAccountsScreen({super.key, required this.user});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final _bankService = BankAccountService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageAccounting,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank & Cash Accounts'),
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  SidePanel.show(
                    context: context,
                    title: 'Add Bank/Cash Account',
                    child: AddBankAccountDialog(
                      companyId: widget.user.companyId!,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Account'),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<BankAccountModel>>(
        stream: _bankService.getBankAccounts(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = snapshot.data ?? [];

          if (accounts.isEmpty) {
            return const Center(child: Text('No bank or cash accounts found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTypeColor(
                      account.accountType,
                    ).withValues(alpha: 0.1),
                    child: Icon(
                      _getTypeIcon(account.accountType),
                      color: _getTypeColor(account.accountType),
                    ),
                  ),
                  title: Text(
                    account.accountName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    account.bankName ?? account.accountType.name.toUpperCase(),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${account.currency} ${NumberFormat('#,##0.00').format(account.currentBalance)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        account.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: account.isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getTypeIcon(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return Icons.money;
      case BankAccountType.bank:
        return Icons.account_balance;
      case BankAccountType.card:
        return Icons.credit_card;
      case BankAccountType.wallet:
        return Icons.account_balance_wallet;
    }
  }

  Color _getTypeColor(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return Colors.green;
      case BankAccountType.bank:
        return Colors.blue;
      case BankAccountType.card:
        return Colors.orange;
      case BankAccountType.wallet:
        return Colors.purple;
    }
  }
}
