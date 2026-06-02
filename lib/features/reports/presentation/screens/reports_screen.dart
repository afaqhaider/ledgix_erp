import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'trial_balance_screen.dart';
import 'profit_loss_screen.dart';
import 'balance_sheet_screen.dart';
import 'general_ledger_screen.dart';

class ReportsScreen extends StatelessWidget {
  final AppUser user;
  const ReportsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(
            context,
            'Trial Balance',
            'View all account balances to ensure the books are balanced.',
            Icons.account_balance,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TrialBalanceScreen(user: user)),
            ),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            'Profit & Loss',
            'Analyze your revenue, costs, and expenses over a period.',
            Icons.trending_up,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfitLossScreen(user: user)),
            ),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            'Balance Sheet',
            'A snapshot of your assets, liabilities, and equity.',
            Icons.pie_chart,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BalanceSheetScreen(user: user)),
            ),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            'General Ledger',
            'Detailed drill-down for any specific account.',
            Icons.list_alt,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GeneralLedgerScreen(user: user),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
