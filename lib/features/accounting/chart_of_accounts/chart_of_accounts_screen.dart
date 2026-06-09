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
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Column(
      children: [
        _buildHeader(theme, canManage),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search accounts by name or code...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
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
                return _buildEmptyState(theme, canManage);
              }

              final visibleAccounts = _buildVisibleAccounts(allAccounts);

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
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 60,
                        horizontalMargin: 24,
                        columnSpacing: 40,
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                        ),
                        columns: [
                          _buildColumn('Code'),
                          _buildColumn('Name'),
                          _buildColumn('Category'),
                          _buildColumn('Type'),
                          _buildColumn('Posting'),
                          _buildColumn('Balance', numeric: true),
                          _buildColumn('Actions'),
                        ],
                        rows: visibleAccounts.map((account) {
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
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: account.isGroup
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: account.isGroup
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
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
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.folder_open_outlined,
                                                  size: 16,
                                                  color: theme
                                                      .colorScheme
                                                      .primary
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
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: account.isGroup
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: account.isGroup
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _getDisplayCategory(account),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              DataCell(_buildTypeBadge(account.accountType)),
                              DataCell(
                                account.allowPosting
                                    ? Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                        color: Colors.blue.withValues(
                                          alpha: 0.7,
                                        ),
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
                                      NumberFormat(
                                        '#,##0.00',
                                      ).format(account.openingBalance),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 13,
                                        fontWeight: account.isGroup
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      account.openingBalanceType.shortLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            account.openingBalanceType ==
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
                                      onPressed: () => _showAddAccountDialog(
                                        context,
                                        account: account,
                                        isReadOnly: true,
                                      ),
                                      tooltip: 'View',
                                    ),
                                    if (canManage &&
                                        !account.isSystemAccount) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () => _showAddAccountDialog(
                                          context,
                                          account: account,
                                        ),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _confirmDelete(account),
                                        tooltip: 'Delete',
                                      ),
                                    ],
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
                  'Chart of Accounts',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage your general ledger accounts and structure',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (canManage) ...[
            _buildHeaderAction(
              icon: Icons.south_west_rounded,
              label: 'Import',
              onTap: () => _showImportModal(context),
            ),
            const SizedBox(width: 8),
            _buildHeaderAction(
              icon: Icons.north_east_rounded,
              label: 'Export',
              onTap: () => _showExportModal(context),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddAccountDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Account'),
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
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildEmptyState(ThemeData theme, bool canManage) {
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
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          if (canManage) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddAccountDialog(context),
              child: const Text('Add Your First Account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
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

  void _showAddAccountDialog(
    BuildContext context, {
    AccountModel? account,
    bool isReadOnly = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(
        companyId: widget.user.companyId!,
        account: account,
        isReadOnly: isReadOnly,
      ),
    );
  }

  Future<void> _confirmDelete(AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete ${account.accountName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _accountService.deleteAccount(widget.user.companyId!, account.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          showErpError(
            context: context,
            title: 'Delete Failed',
            message: e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
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
