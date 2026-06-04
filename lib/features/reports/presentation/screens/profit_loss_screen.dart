import 'package:flutter/material.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import '../../models/report_models.dart';
import '../../services/financial_report_service.dart';

class ProfitLossScreen extends StatefulWidget {
  final String companyId;

  const ProfitLossScreen({super.key, required this.companyId});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  final _reportService = FinancialReportService();
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();
  ProfitLossReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final report = await _reportService.getProfitLoss(
      widget.companyId,
      _startDate,
      _endDate,
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
        title: const Text('Profit & Loss'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                initialDateRange: DateTimeRange(
                  start: _startDate,
                  end: _endDate,
                ),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (range != null) {
                setState(() {
                  _startDate = range.start;
                  _endDate = range.end;
                });
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
                    'From ${AppFormatters.date(_startDate)} to ${AppFormatters.date(_endDate)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ...(_report?.sections.map((s) => _buildSection(s)).toList() ??
                    []),
                const Divider(thickness: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NET PROFIT',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppFormatters.currency(_report?.netProfit ?? 0),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: (_report?.netProfit ?? 0) >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(ReportSection section) {
    if (section.lines.isEmpty) return const SizedBox.shrink();

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
}
