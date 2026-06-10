import 'package:flutter/material.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import '../../models/report_models.dart';
import '../../services/financial_report_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/services/export_service.dart';

class StatementOfChangesInEquityScreen extends StatefulWidget {
  final String companyId;

  const StatementOfChangesInEquityScreen({super.key, required this.companyId});

  @override
  State<StatementOfChangesInEquityScreen> createState() =>
      _StatementOfChangesInEquityScreenState();
}

class _StatementOfChangesInEquityScreenState
    extends State<StatementOfChangesInEquityScreen> {
  final _reportService = FinancialReportService();
  final _exportService = ExportService();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, 1, 1),
    end: DateTime.now(),
  );
  StatementOfChangesInEquityReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final report = await _reportService.getStatementOfChangesInEquity(
        widget.companyId,
        _dateRange.start,
        _dateRange.end,
      );
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  void _exportExcel() {
    if (_report == null) return;

    final headers = ['Account', 'Opening', 'Net Income', 'Other Changes', 'Closing'];
    final rows = _report!.nodes.map((n) => [
      n.accountName,
      n.openingBalance,
      n.netIncomeAllocated,
      n.otherChanges,
      n.closingBalance,
    ]).toList();
    
    // Add total row
    rows.add([
      'TOTAL EQUITY',
      _report!.totalOpeningBalance,
      _report!.totalNetIncome,
      _report!.totalOtherChanges,
      _report!.totalClosingBalance,
    ]);

    _exportService.exportToExcel(
      fileName: 'Statement_of_Changes_in_Equity',
      sheetName: 'Equity',
      headers: headers,
      data: rows,
    );
  }

  void _exportPdf() {
    if (_report == null) return;

    final headers = ['Account', 'Opening', 'Net Income', 'Changes', 'Closing'];
    final rows = _report!.nodes.map((n) => [
      n.accountName,
      AppFormatters.currency(n.openingBalance),
      AppFormatters.currency(n.netIncomeAllocated),
      AppFormatters.currency(n.otherChanges),
      AppFormatters.currency(n.closingBalance),
    ]).toList();

    _exportService.exportReportToPdf(
      title: 'Statement of Changes in Equity',
      subTitle: 'From ${AppFormatters.date(_dateRange.start)} to ${AppFormatters.date(_dateRange.end)}',
      headers: headers,
      data: rows,
      summary: {
        'Total Opening Balance': AppFormatters.currency(_report!.totalOpeningBalance),
        'Total Net Income': AppFormatters.currency(_report!.totalNetIncome),
        'Total Other Changes': AppFormatters.currency(_report!.totalOtherChanges),
        'Total Closing Balance': AppFormatters.currency(_report!.totalClosingBalance),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statement of Changes in Equity',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(theme),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_report == null || _report!.nodes.isEmpty)
            const Expanded(child: Center(child: Text('No equity activity found for this period.')))
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          theme.colorScheme.surfaceContainer,
                        ),
                        border: TableBorder.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 0.5,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              'ACCOUNT',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'OPENING',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'NET INCOME',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'OTHER CHANGES',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'CLOSING',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        rows: [
                          ..._report!.nodes.map((node) => DataRow(
                                cells: [
                                  DataCell(Text(node.accountName, style: GoogleFonts.inter(fontSize: 13))),
                                  DataCell(Text(AppFormatters.currency(node.openingBalance), style: GoogleFonts.jetBrainsMono(fontSize: 13))),
                                  DataCell(Text(AppFormatters.currency(node.netIncomeAllocated), style: GoogleFonts.jetBrainsMono(fontSize: 13))),
                                  DataCell(Text(AppFormatters.currency(node.otherChanges), style: GoogleFonts.jetBrainsMono(fontSize: 13))),
                                  DataCell(Text(
                                    AppFormatters.currency(node.closingBalance),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )),
                                ],
                              )),
                          DataRow(
                            color: WidgetStateProperty.all(
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                            ),
                            cells: [
                              DataCell(Text(
                                'TOTAL EQUITY',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                              )),
                              DataCell(Text(
                                AppFormatters.currency(_report!.totalOpeningBalance),
                                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800),
                              )),
                              DataCell(Text(
                                AppFormatters.currency(_report!.totalNetIncome),
                                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800),
                              )),
                              DataCell(Text(
                                AppFormatters.currency(_report!.totalOtherChanges),
                                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800),
                              )),
                              DataCell(Text(
                                AppFormatters.currency(_report!.totalClosingBalance),
                                style: GoogleFonts.jetBrainsMono(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equity Movements',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Changes from ${AppFormatters.date(_dateRange.start)} to ${AppFormatters.date(_dateRange.end)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                initialDateRange: _dateRange,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (range != null) {
                setState(() => _dateRange = range);
                _loadReport();
              }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text('Change Period'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Report',
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
}
