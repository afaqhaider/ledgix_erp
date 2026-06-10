import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/reports/services/job_report_service.dart';
import 'package:ledgixerp/core/services/export_service.dart';

class JobDrillDownModal extends StatefulWidget {
  final String companyId;
  final String jobId;
  final String jobName;
  final String jobNumber;

  const JobDrillDownModal({
    super.key,
    required this.companyId,
    required this.jobId,
    required this.jobName,
    required this.jobNumber,
  });

  static void show(
    BuildContext context, {
    required String companyId,
    required String jobId,
    required String jobName,
    required String jobNumber,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: JobDrillDownModal(
          companyId: companyId,
          jobId: jobId,
          jobName: jobName,
          jobNumber: jobNumber,
        ),
      ),
    );
  }

  @override
  State<JobDrillDownModal> createState() => _JobDrillDownModalState();
}

class _JobDrillDownModalState extends State<JobDrillDownModal> {
  final _service = JobReportService();
  final _exportService = ExportService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _data = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getJobLedger(widget.companyId, widget.jobId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _exportExcel() {
    if (_data.isEmpty) return;
    
    final headers = ['Date', 'Description', 'Reference', 'Account', 'Debit', 'Credit', 'Profit Impact', 'Running P/L'];
    final rows = _data.map((item) => [
      AppFormatters.date(item['date']),
      item['description'] ?? '',
      item['reference'] ?? '',
      item['accountName'] ?? '',
      item['debit'],
      item['credit'],
      item['impact'],
      item['runningBalance'],
    ]).toList();

    _exportService.exportToExcel(
      fileName: 'Job_Ledger_${widget.jobNumber}',
      sheetName: 'Ledger',
      headers: headers,
      data: rows,
    );
  }

  void _exportPdf() {
    if (_data.isEmpty) return;

    final headers = ['Date', 'Description', 'Ref', 'Account', 'Dr', 'Cr', 'Impact', 'Balance'];
    final rows = _data.map((item) => [
      AppFormatters.date(item['date']),
      item['description']?.toString() ?? '',
      item['reference']?.toString() ?? '',
      item['accountName']?.toString() ?? '',
      AppFormatters.currency(item['debit']),
      AppFormatters.currency(item['credit']),
      AppFormatters.currency(item['impact']),
      AppFormatters.currency(item['runningBalance']),
    ]).toList();

    final totalProfit = _data.last['runningBalance'] as double;

    _exportService.exportReportToPdf(
      title: 'Job Detail Ledger',
      subTitle: 'Job: ${widget.jobName} (${widget.jobNumber})',
      headers: headers,
      data: rows,
      summary: {
        'Total Job Profit / Loss': AppFormatters.currency(totalProfit),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 1100,
      constraints: const BoxConstraints(maxHeight: 800),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          _buildFilters(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                ? _buildEmptyState()
                : _buildTable(theme),
          ),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.jobNumber,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.jobName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Job Ledger / All associated transactions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search ledger...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Ledger',
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No transactions found for this job'),
        ],
      ),
    );
  }

  Widget _buildTable(ThemeData theme) {
    final filtered = _data
        .where(
          (item) =>
              item['description'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item['reference'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item['accountName'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Reference')),
          DataColumn(label: Text('Account')),
          DataColumn(label: Text('Debit'), numeric: true),
          DataColumn(label: Text('Credit'), numeric: true),
          DataColumn(label: Text('Profit Impact'), numeric: true),
          DataColumn(label: Text('Running P/L'), numeric: true),
        ],
        rows: filtered.map((item) {
          final impact = item['impact'] as double;
          return DataRow(
            cells: [
              DataCell(Text(AppFormatters.date(item['date']))),
              DataCell(Text(item['description'])),
              DataCell(Text(item['reference'])),
              DataCell(Text(item['accountName'])),
              DataCell(
                Text(
                  item['debit'] > 0
                      ? AppFormatters.currency(item['debit'])
                      : '—',
                ),
              ),
              DataCell(
                Text(
                  item['credit'] > 0
                      ? AppFormatters.currency(item['credit'])
                      : '—',
                ),
              ),
              DataCell(
                Text(
                  AppFormatters.currency(impact),
                  style: TextStyle(
                    color: impact > 0 ? Colors.green : (impact < 0 ? Colors.red : null),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  AppFormatters.currency(item['runningBalance']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final totalProfit = _data.isNotEmpty ? _data.last['runningBalance'] : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'TOTAL JOB PROFIT / LOSS: ',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Text(
            AppFormatters.currency(totalProfit),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: totalProfit >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
