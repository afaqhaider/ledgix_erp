import 'package:flutter/material.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import '../../models/report_models.dart';
import '../../services/financial_report_service.dart';

class BalanceSheetScreen extends StatefulWidget {
  final String companyId;

  const BalanceSheetScreen({super.key, required this.companyId});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  final _reportService = FinancialReportService();
  DateTime _asOfDate = DateTime.now();
  BalanceSheetReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final report = await _reportService.getBalanceSheet(
      widget.companyId,
      _asOfDate,
    );
    setState(() {
      _report = report;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Sheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _asOfDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _asOfDate = date);
                _loadReport();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: Text(
                    'As of ${AppFormatters.date(_asOfDate)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ...(_report?.sections.map((s) => _buildSection(s)).toList() ??
                    []),
                const Divider(thickness: 2),
                if (_report != null && !_report!.isBalanced)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Center(
                      child: Text(
                        'WARNING: Assets do not equal Liabilities + Equity',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                _buildSummaryRow(
                  'TOTAL ASSETS',
                  _report?.totalAssets ?? 0,
                  isBold: true,
                ),
                _buildSummaryRow(
                  'TOTAL LIABILITIES',
                  _report?.totalLiabilities ?? 0,
                ),
                _buildSummaryRow('TOTAL EQUITY', _report?.totalEquity ?? 0),
                const Divider(),
                _buildSummaryRow(
                  'TOTAL LIABILITIES & EQUITY',
                  (_report?.totalLiabilities ?? 0) +
                      (_report?.totalEquity ?? 0),
                  isBold: true,
                ),
              ],
            ),
    );
  }

  Widget _buildSection(ReportSection section) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        ...section.lines.map(
          (l) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(l.name), Text(AppFormatters.currency(l.balance))],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ${section.title}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                AppFormatters.currency(section.total),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
          Text(
            AppFormatters.currency(value),
            style: isBold
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }
}
