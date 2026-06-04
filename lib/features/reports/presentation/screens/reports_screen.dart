import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'trial_balance_screen.dart';
import 'profit_loss_screen.dart';
import 'balance_sheet_screen.dart';
import 'general_ledger_screen.dart';
import 'account_statement_screen.dart';

class ReportsScreen extends StatelessWidget {
  final AppUser user;
  const ReportsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final companyId = user.companyId!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Reports')),
      body: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildReportCard(
                context,
                'Trial Balance',
                'View all account balances to ensure the books are balanced.',
                Icons.account_balance,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrialBalanceScreen(companyId: companyId),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                context,
                'Profit & Loss',
                'Analyze your revenue, costs, and expenses over a period.',
                Icons.trending_up,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfitLossScreen(companyId: companyId),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                context,
                'Balance Sheet',
                'A snapshot of your assets, liabilities, and equity.',
                Icons.pie_chart,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BalanceSheetScreen(companyId: companyId),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                context,
                'General Ledger',
                'Detailed drill-down for any specific account.',
                Icons.list_alt,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeneralLedgerScreen(companyId: companyId),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                context,
                'Account Statement',
                'Generate a formal statement for any GL account.',
                Icons.description_outlined,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AccountStatementScreen(companyId: companyId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }
}
