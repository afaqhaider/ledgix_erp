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
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 52,
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
                          _buildColumn('Postable'),
                          _buildColumn('Balance', numeric: true),
                        ],
                        rows: visibleAccounts.map((account) {
                          final bool isExpanded = _expandedAccountIds.contains(
                            account.id,
                          );
                          final bool hasChildren = allAccounts.any(
                            (a) => a.parentAccountId == account.id,
                          );

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  account.accountCode,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: account.isGroup
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: account.isGroup
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
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
                                            isExpanded
                                                ? Icons.keyboard_arrow_down_rounded
                                                : Icons.keyboard_arrow_right_rounded,
                                            size: 20,
                                            color: theme.colorScheme.primary,
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        account.accountName,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: account.isGroup
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  account.accountCategory.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(_buildTypeBadge(account.accountType)),
                              DataCell(
                                Text(
                                  account.allowPosting ? 'Yes' : 'No',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: account.allowPosting
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${NumberFormat('#,##0.00').format(account.openingBalance)} ${account.openingBalanceType.label.substring(0, 2)}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                    fontWeight: account.isGroup
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
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
              icon: Icons.file_upload_outlined,
              label: 'Import',
              onTap: () => _showImportModal(context),
            ),
            const SizedBox(width: 8),
            _buildHeaderAction(
              icon: Icons.file_download_outlined,
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
