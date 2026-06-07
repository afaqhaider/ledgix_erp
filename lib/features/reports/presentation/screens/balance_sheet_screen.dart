import 'package:flutter/material.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import '../../models/report_models.dart';
import '../../services/financial_report_service.dart';

import 'package:google_fonts/google_fonts.dart';

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

    return Column(
      children: [
        _buildHeader(theme),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSummaryBar(theme),
                const SizedBox(height: 24),
                ...(_report?.sections.map((s) => _buildSection(s)).toList() ??
                    []),
                const Divider(thickness: 1.5, height: 40),
                if (_report != null && !_report!.isBalanced)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'WARNING: Assets do not equal Liabilities + Equity',
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildSummaryRow(
                  'TOTAL ASSETS',
                  _report?.totalAssets ?? 0,
                  isPrimary: true,
                ),
                _buildSummaryRow(
                  'TOTAL LIABILITIES',
                  _report?.totalLiabilities ?? 0,
                ),
                _buildSummaryRow('TOTAL EQUITY', _report?.totalEquity ?? 0),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                _buildSummaryRow(
                  'TOTAL LIABILITIES & EQUITY',
                  (_report?.totalLiabilities ?? 0) +
                      (_report?.totalEquity ?? 0),
                  isPrimary: true,
                  isFinal: true,
                ),
              ],
            ),
          ),
      ],
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
                  'Balance Sheet',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Snapshot of financial position as of a specific date',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
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
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(AppFormatters.date(_asOfDate)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export PDF',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'As of ${AppFormatters.date(_asOfDate)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
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
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            section.title.toUpperCase(),
            style: GoogleFonts.inter(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        ...section.lines.map(
          (l) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  AppFormatters.currency(l.balance),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.15,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ${section.title}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                AppFormatters.currency(section.total),
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isPrimary = false,
    bool isFinal = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: EdgeInsets.all(isPrimary ? 16 : 12),
        decoration: isPrimary
            ? BoxDecoration(
              color: isFinal
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: isFinal
                  ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2))
                  : null,
            )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                fontSize: isPrimary ? 15 : 14,
                color: isFinal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              AppFormatters.currency(value),
              style: GoogleFonts.jetBrainsMono(
                fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
                fontSize: isPrimary ? 17 : 15,
                color: isFinal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
