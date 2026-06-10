import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/reports/services/job_report_service.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';
import 'package:ledgixerp/features/settings/models/financial_settings_model.dart';
import 'package:ledgixerp/core/services/export_service.dart';
import '../widgets/job_drill_down_modal.dart';

class JobReportScreen extends StatefulWidget {
  final String companyId;
  const JobReportScreen({super.key, required this.companyId});

  @override
  State<JobReportScreen> createState() => _JobReportScreenState();
}

class _JobReportScreenState extends State<JobReportScreen> {
  final _service = JobReportService();
  final _settingsService = FinancialSettingsService();
  final _exportService = ExportService();
  List<JobReportData>? _data;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getJobReports(widget.companyId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _exportExcel() {
    if (_data == null || _data!.isEmpty) return;
    
    final headers = ['Job #', 'Job Name', 'Revenue', 'Expenses', 'Profit/Loss', 'Budget P/L', 'Variance', 'Margin %'];
    final rows = _data!.map((d) => [
      d.job.jobNumber,
      d.job.jobName,
      d.actualRevenue,
      d.actualExpense,
      d.actualProfitLoss,
      d.job.expectedProfitLoss,
      d.variance,
      d.profitMargin,
    ]).toList();

    _exportService.exportToExcel(
      fileName: 'Job_Profitability_Report',
      sheetName: 'Profitability',
      headers: headers,
      data: rows,
    );
  }

  void _exportPdf() {
    if (_data == null || _data!.isEmpty) return;

    final headers = ['Job #', 'Job Name', 'Revenue', 'Expenses', 'P/L', 'Margin %'];
    final rows = _data!.map((d) => [
      d.job.jobNumber,
      d.job.jobName,
      AppFormatters.currency(d.actualRevenue),
      AppFormatters.currency(d.actualExpense),
      AppFormatters.currency(d.actualProfitLoss),
      '${d.profitMargin.toStringAsFixed(1)}%',
    ]).toList();

    final totalRevenue = _data!.fold(0.0, (sum, d) => sum + d.actualRevenue);
    final totalExpense = _data!.fold(0.0, (sum, d) => sum + d.actualExpense);

    _exportService.exportReportToPdf(
      title: 'Job Profitability Report',
      subTitle: 'Summary of all active projects',
      headers: headers,
      data: rows,
      summary: {
        'Total Revenue': AppFormatters.currency(totalRevenue),
        'Total Expenses': AppFormatters.currency(totalExpense),
        'Net Profit': AppFormatters.currency(totalRevenue - totalExpense),
      },
    );
  }

  List<JobReportData> _getFilteredData() {
    if (_data == null) return [];
    if (_searchQuery.isEmpty) return _data!;
    return _data!.where((d) =>
      d.job.jobName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      d.job.jobNumber.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FinancialSettingsModel>(
      stream: _settingsService.streamSettings(widget.companyId),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data;
        final enabled = settings?.jobBasedAccountingEnabled ?? true;

        if (settingsSnapshot.hasData && !enabled) {
          return Scaffold(
            appBar: AppBar(title: const Text('Job Profitability')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Job-Based Accounting is disabled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Enable it in Settings > Financial Settings to use this feature.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final theme = Theme.of(context);
        final filteredData = _getFilteredData();

        return Column(
          children: [
        _buildHeader(theme),
        _buildControls(theme),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (filteredData.isEmpty)
          const Expanded(child: Center(child: Text('No job data available.')))
        else
          Expanded(
            child: Column(
              children: [
                _buildSummaryBar(theme),
                _buildTableHeader(theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      return _buildJobRow(theme, filteredData[index]);
                    },
                  ),
                ),
                _buildTotalFooter(theme, filteredData),
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
                  'Job Profitability',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Track revenue, expenses, and margins by project',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Profitability',
            onSelected: (value) {
              if (value == 'excel') _exportExcel();
              if (value == 'pdf') _exportPdf();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Export as Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              hintText: 'Search jobs...',
              leading: const Icon(Icons.search, size: 20),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainer,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
            'Showing profitability for all active jobs',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'JOB / PROJECT',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _buildHeaderCell('REVENUE', 120),
          _buildHeaderCell('EXPENSES', 120),
          _buildHeaderCell('ACTUAL P/L', 120),
          _buildHeaderCell('BUDGET P/L', 120),
          _buildHeaderCell('VARIANCE', 120),
          _buildHeaderCell('MARGIN %', 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildJobRow(ThemeData theme, JobReportData data) {
    return InkWell(
      onTap: () => JobDrillDownModal.show(
        context,
        companyId: widget.companyId,
        jobId: data.job.id,
        jobName: data.job.jobName,
        jobNumber: data.job.jobNumber,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.job.jobName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    data.job.jobNumber,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            _buildValueCell(data.actualRevenue),
            _buildValueCell(data.actualExpense),
            _buildValueCell(data.actualProfitLoss, isBold: true, useColor: true),
            _buildValueCell(data.job.expectedProfitLoss),
            _buildValueCell(data.variance, useColor: true),
            _buildValueCell(data.profitMargin, isPercentage: true, width: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCell(double value, {
    bool isBold = false,
    bool useColor = false,
    bool isPercentage = false,
    double width = 120,
  }) {
    Color? color;
    if (useColor) {
      color = value >= 0 ? Colors.green : Colors.red;
    }
    return SizedBox(
      width: width,
      child: Text(
        isPercentage ? '${value.toStringAsFixed(1)}%' : AppFormatters.currency(value),
        textAlign: TextAlign.right,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTotalFooter(ThemeData theme, List<JobReportData> data) {
    final totalRevenue = data.fold(0.0, (sum, d) => sum + d.actualRevenue);
    final totalExpense = data.fold(0.0, (sum, d) => sum + d.actualExpense);
    final totalProfit = totalRevenue - totalExpense;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildTotalItem(theme, 'TOTAL REVENUE', totalRevenue),
          const SizedBox(width: 40),
          _buildTotalItem(theme, 'TOTAL EXPENSES', totalExpense),
          const SizedBox(width: 40),
          _buildTotalItem(theme, 'NET PROFIT', totalProfit, isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildTotalItem(ThemeData theme, String label, double value, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          AppFormatters.currency(value),
          style: GoogleFonts.jetBrainsMono(
            fontSize: isPrimary ? 18 : 15,
            fontWeight: FontWeight.w800,
            color: isPrimary ? theme.colorScheme.primary : (value < 0 ? Colors.red : null),
          ),
        ),
      ],
    );
  }
}
