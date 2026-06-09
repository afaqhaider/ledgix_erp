import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';
import 'package:ledgixerp/features/settings/models/financial_settings_model.dart';
import 'trial_balance_screen.dart';
import 'profit_loss_screen.dart';
import 'balance_sheet_screen.dart';
import 'job_report_screen.dart';
import 'general_ledger_screen.dart';
import 'account_statement_screen.dart';

class ReportsDashboardScreen extends StatefulWidget {
  final String companyId;

  const ReportsDashboardScreen({super.key, required this.companyId});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  final _settingsService = FinancialSettingsService();
  bool _jobBasedAccountingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettings(widget.companyId);
    if (mounted) {
      setState(() {
        _jobBasedAccountingEnabled = settings.jobBasedAccountingEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<FinancialSettingsModel>(
      stream: _settingsService.streamSettings(widget.companyId),
      builder: (context, snapshot) {
        final enabled = snapshot.data?.jobBasedAccountingEnabled ?? _jobBasedAccountingEnabled;

        return Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(AppSpacing.lg),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
                children: [
                  _buildReportCard(
                    context,
                    'Trial Balance',
                    'Summary of all ledger balances.',
                    Icons.account_balance_wallet,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrialBalanceScreen(companyId: widget.companyId),
                      ),
                    ),
                  ),
                  _buildReportCard(
                    context,
                    'Profit & Loss',
                    'Income and expenses overview.',
                    Icons.trending_up,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfitLossScreen(companyId: widget.companyId),
                      ),
                    ),
                  ),
                  _buildReportCard(
                    context,
                    'Balance Sheet',
                    'Financial position as of date.',
                    Icons.pie_chart,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BalanceSheetScreen(companyId: widget.companyId),
                      ),
                    ),
                  ),
                  if (enabled)
                    _buildReportCard(
                      context,
                      'Job Profitability',
                      'Track revenue and expenses per project.',
                      Icons.assignment_turned_in,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobReportScreen(companyId: widget.companyId),
                        ),
                      ),
                    ),
                  _buildReportCard(
                    context,
                    'General Ledger',
                    'Detailed drill-down for any specific account.',
                    Icons.list_alt,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GeneralLedgerScreen(companyId: widget.companyId),
                      ),
                    ),
                  ),
                  _buildReportCard(
                    context,
                    'Account Statement',
                    'Formal statement for any GL account.',
                    Icons.description_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AccountStatementScreen(companyId: widget.companyId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Reports',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Analyze your business performance with real-time financial data',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
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
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
