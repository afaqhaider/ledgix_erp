import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/add_account_dialog.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/import_export_modal.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/export_modal.dart';
import 'package:ledgixerp/features/data_migration/models/migration_models.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  final AppUser user;
  const ChartOfAccountsScreen({super.key, required this.user});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final _accountService = AccountService();
  final Set<String> _expandedAccountIds = {};

  void _toggleExpanded(String accountId) {
    setState(() {
      if (_expandedAccountIds.contains(accountId)) {
        _expandedAccountIds.remove(accountId);
      } else {
        _expandedAccountIds.add(accountId);
      }
    });
  }

  List<AccountModel> _buildVisibleAccounts(List<AccountModel> allAccounts) {
    final List<AccountModel> visibleAccounts = [];
    final Map<String?, List<AccountModel>> accountsByParent = {};

    for (final account in allAccounts) {
      accountsByParent.putIfAbsent(account.parentAccountId, () => []).add(account);
    }

    void addChildren(String? parentId) {
      final children = accountsByParent[parentId] ?? [];
      // Sort children by account code
      children.sort((a, b) => a.accountCode.compareTo(b.accountCode));

      for (final child in children) {
        visibleAccounts.add(child);
        if (child.isGroup && _expandedAccountIds.contains(child.id)) {
          addChildren(child.id);
        }
      }
    }

    addChildren(null);
    return visibleAccounts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageAccounting,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart of Accounts'),
        actions: [
          if (canManage) ...[
            OutlinedButton.icon(
              onPressed: () => _showImportModal(context),
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Import'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showExportModal(context),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Export'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddAccountDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(width: 16),
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

          final allAccounts = snapshot.data ?? [];

          if (allAccounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _showAddAccountDialog(context),
                      child: const Text('Add Your First Account'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        setState(() {}); // Show loading if needed
                        await _accountService.seedDefaultAccounts(
                          widget.user.companyId!,
                        );
                      },
                      child: const Text('Seed Default Chart of Accounts'),
                    ),
                  ],
                ],
              ),
            );
          }

          final visibleAccounts = _buildVisibleAccounts(allAccounts);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: DataTable(
                  horizontalMargin: 24,
                  columnSpacing: 40,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Code',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Type',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Postable',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Balance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: visibleAccounts.map((account) {
                    final bool isExpanded = _expandedAccountIds.contains(account.id);
                    final bool hasChildren = allAccounts.any((a) => a.parentAccountId == account.id);

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            account.accountCode,
                            style: TextStyle(
                              fontWeight: account.level == 0 
                                  ? FontWeight.bold 
                                  : (account.isGroup ? FontWeight.w600 : FontWeight.normal),
                            ),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: EdgeInsets.only(
                              left: account.level * 24.0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (account.isGroup && hasChildren)
                                  InkWell(
                                    onTap: () => _toggleExpanded(account.id),
                                    child: Icon(
                                      isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                else
                                  const SizedBox(width: 18),
                                const SizedBox(width: 8),
                                Text(
                                  account.accountName,
                                  style: TextStyle(
                                    fontWeight: account.level == 0 
                                        ? FontWeight.bold 
                                        : (account.isGroup ? FontWeight.w600 : FontWeight.normal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(account.accountCategory.label)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(
                                account.accountType,
                              ).withValues(alpha: 0.1),
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
                          Text(
                            account.allowPosting ? 'Yes' : 'No',
                            style: TextStyle(
                              color: account.allowPosting ? Colors.blue : Colors.grey,
                              fontWeight: account.allowPosting ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${NumberFormat('#,##0.00').format(account.openingBalance)} ${account.openingBalanceType.label.substring(0, 2)}',
                            style: TextStyle(
                              fontWeight: account.level == 0 
                                  ? FontWeight.bold 
                                  : (account.isGroup ? FontWeight.w600 : FontWeight.w500),
                            ),
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
      case AccountType.asset:
        return Colors.blue;
      case AccountType.liability:
        return Colors.orange;
      case AccountType.equity:
        return Colors.purple;
      case AccountType.income:
        return Colors.green;
      case AccountType.costOfSales:
        return Colors.deepOrange;
      case AccountType.expense:
        return Colors.red;
      case AccountType.otherIncome:
        return Colors.teal;
      case AccountType.otherExpense:
        return Colors.brown;
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(companyId: widget.user.companyId!),
    );
  }

  void _showImportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImportExportModal(
        initialModule: MigrationModule.chartOfAccounts,
        companyId: widget.user.companyId!,
      ),
    );
  }

  void _showExportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          const ExportModal(initialModule: MigrationModule.chartOfAccounts),
    );
  }
}
