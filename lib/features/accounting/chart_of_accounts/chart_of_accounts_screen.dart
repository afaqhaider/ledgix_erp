import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/widgets/erp_layout.dart';
import 'package:ledgixerp/core/widgets/erp_data_table.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_pane.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/import_export_modal.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/export_modal.dart';
import 'package:ledgixerp/features/data_migration/models/migration_models.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  final AppUser user;
  const ChartOfAccountsScreen({super.key, required this.user});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final _accountService = AccountService();
  final Set<String> _expandedAccountIds = {};
  String _searchQuery = '';

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
    final filteredAccounts = allAccounts.where((account) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return account.accountName.toLowerCase().contains(query) ||
          account.accountCode.toLowerCase().contains(query);
    }).toList();

    if (_searchQuery.isNotEmpty) return filteredAccounts;

    final List<AccountModel> visibleAccounts = [];
    final Map<String?, List<AccountModel>> accountsByParent = {};

    for (final account in allAccounts) {
      accountsByParent
          .putIfAbsent(account.parentAccountId, () => [])
          .add(account);
    }

    void addChildren(String? parentId) {
      final children = accountsByParent[parentId] ?? [];
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
    final isDark = theme.brightness == Brightness.dark;
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageAccounting,
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          ERPPageHeader(
            title: 'Chart of Accounts',
            subtitle: 'Manage your general ledger accounts and structure',
            actions: [
              if (canManage) ...[
                OutlinedButton.icon(
                  onPressed: () => _showImportModal(context),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('Import'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showExportModal(context),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAccountPane(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Account'),
                ),
              ],
            ],
          ),
          ERPActionToolbar(
            searchField: SizedBox(
              height: 40,
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search accounts by name or code...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AccountModel>>(
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
                  return ERPEmptyState(
                    title: 'No accounts found',
                    message: 'Get started by adding your first account',
                    icon: Icons.account_balance_wallet_outlined,
                    action: canManage
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _showAccountPane(context),
                                child: const Text('Add Your First Account'),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () async {
                                  await _accountService.seedDefaultAccounts(
                                    widget.user.companyId!,
                                  );
                                },
                                child: const Text(
                                  'Seed Default Chart of Accounts',
                                ),
                              ),
                            ],
                          )
                        : null,
                  );
                }

                final visibleAccounts = _buildVisibleAccounts(allAccounts);

                return ERPDataTable<AccountModel>(
                  columns: const [
                    'CODE',
                    'NAME',
                    'CATEGORY',
                    'TYPE',
                    'POSTING',
                    'BALANCE',
                    '',
                  ],
                  items: visibleAccounts,
                  rowBuilder: (account, index) {
                    final bool isExpanded = _expandedAccountIds.contains(
                      account.id,
                    );
                    final bool hasChildren = allAccounts.any(
                      (a) => a.parentAccountId == account.id,
                    );

                    return DataRow(
                      color: account.isGroup
                          ? WidgetStateProperty.all(
                              isDark
                                  ? Colors.white.withValues(alpha: 0.02)
                                  : Colors.grey.withValues(alpha: 0.03),
                            )
                          : null,
                      cells: [
                        DataCell(
                          Text(
                            account.accountCode,
                            style: TextStyle(
                              fontWeight: account.isGroup
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        DataCell(
                          Padding(
                            padding: EdgeInsets.only(
                              left: account.level * 20.0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (account.isGroup)
                                  SizedBox(
                                    width: 24,
                                    child: hasChildren
                                        ? InkWell(
                                            onTap: () => _toggleExpanded(
                                              account.id,
                                            ),
                                            child: Icon(
                                              isExpanded
                                                  ? Icons
                                                        .keyboard_arrow_down_rounded
                                                  : Icons
                                                        .keyboard_arrow_right_rounded,
                                              size: 20,
                                              color: theme.colorScheme.primary,
                                            ),
                                          )
                                        : Icon(
                                            Icons.folder_open_outlined,
                                            size: 16,
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.5),
                                          ),
                                  )
                                else
                                  const SizedBox(
                                    width: 24,
                                    child: Center(
                                      child: Icon(
                                        Icons.description_outlined,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  account.accountName,
                                  style: TextStyle(
                                    fontWeight: account.isGroup
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(_getDisplayCategory(account))),
                        DataCell(_buildTypeBadge(account.accountType)),
                        DataCell(
                          account.allowPosting
                              ? Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: Colors.blue.withValues(alpha: 0.7),
                                )
                              : const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                        ),
                        DataCell(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.currency(account.openingBalance),
                                style: TextStyle(
                                  fontWeight: account.isGroup
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                account.openingBalanceType.shortLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: account.openingBalanceType ==
                                          BalanceType.debit
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                onPressed: () => _showAccountPane(
                                  context,
                                  account: account,
                                  isReadOnly: true,
                                ),
                                tooltip: 'View',
                                visualDensity: VisualDensity.compact,
                              ),
                              if (canManage && !account.isSystemAccount) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => _showAccountPane(
                                    context,
                                    account: account,
                                  ),
                                  tooltip: 'Edit',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _confirmDelete(account),
                                  tooltip: 'Delete',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTypeBadge(AccountType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor(type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          color: _getTypeColor(type),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
      case AccountType.unknown:
        return Colors.grey;
    }
  }

  String _getDisplayCategory(AccountModel account) {
    if (account.isGroup) {
      // Cleaner major heading categories
      switch (account.accountType) {
        case AccountType.asset:
          return 'Asset';
        case AccountType.liability:
          return 'Liability';
        case AccountType.equity:
          return 'Equity';
        case AccountType.income:
          return 'Revenue';
        case AccountType.costOfSales:
          return 'Cost of Sales';
        case AccountType.expense:
          return 'Expense';
        default:
          return account.accountType.label;
      }
    }

    // Specific mappings for child accounts
    switch (account.accountCategory) {
      case AccountCategory.cash:
        return 'Cash';
      case AccountCategory.bank:
        return 'Bank';
      case AccountCategory.accountsReceivable:
        return 'Accounts Receivable';
      case AccountCategory.accountsPayable:
        return 'Accounts Payable';
      case AccountCategory.vatPayable:
        return 'VAT Payable';
      case AccountCategory.sales:
        return 'Revenue';
      case AccountCategory.serviceIncome:
        return 'Service Revenue';
      case AccountCategory.cogs:
        return 'Cost of Goods Sold';
      case AccountCategory.operatingExpense:
        return 'Operating Expense';
      case AccountCategory.currentAsset:
        return 'Current Asset';
      case AccountCategory.nonCurrentAsset:
        return 'Fixed Asset';
      case AccountCategory.currentLiability:
        return 'Current Liability';
      case AccountCategory.nonCurrentLiability:
        return 'Long Term Liability';
      case AccountCategory.ownerEquity:
        return 'Equity';
      case AccountCategory.staffCost:
        return 'Staff Cost';
      case AccountCategory.rent:
        return 'Rent';
      case AccountCategory.utilities:
        return 'Utilities';
      case AccountCategory.depreciation:
        return 'Depreciation';
      case AccountCategory.adminExpense:
        return 'Admin Expense';
      default:
        return account.accountCategory.label;
    }
  }

  void _showAccountPane(
    BuildContext context, {
    AccountModel? account,
    bool isReadOnly = false,
  }) {
    showErpSidePane(
      context: context,
      builder: AccountPane(
        companyId: widget.user.companyId!,
        account: account,
        isReadOnly: isReadOnly,
      ),
    );
  }

  Future<void> _confirmDelete(AccountModel account) async {
    showDialog(
      context: context,
      builder: (_) => ERPConfirmDeleteDialog(
        title: 'Delete Account',
        message: 'Are you sure you want to delete ${account.accountName}? This action cannot be undone and will fail if the account has transactions.',
        onConfirm: () async {
          try {
            await _accountService.deleteAccount(widget.user.companyId!, account.id);
          } catch (e) {
            if (mounted) {
              showErpError(
                context: context,
                title: 'Delete Failed',
                message: e.toString().replaceFirst('Exception: ', ''),
              );
            }
          }
        },
      ),
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
