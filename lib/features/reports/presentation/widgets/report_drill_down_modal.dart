import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/reports/services/financial_report_service.dart';

class ReportDrillDownModal extends StatefulWidget {
  final String companyId;
  final String accountId;
  final String accountName;
  final String accountCode;
  final AccountCategory category;
  final String? jobId;

  const ReportDrillDownModal({
    super.key,
    required this.companyId,
    required this.accountId,
    required this.accountName,
    required this.accountCode,
    required this.category,
    this.jobId,
  });

  static void show(
    BuildContext context, {
    required String companyId,
    required String accountId,
    required String accountName,
    required String accountCode,
    required AccountCategory category,
    String? jobId,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ReportDrillDownModal(
          companyId: companyId,
          accountId: accountId,
          accountName: accountName,
          accountCode: accountCode,
          category: category,
          jobId: jobId,
        ),
      ),
    );
  }

  @override
  State<ReportDrillDownModal> createState() => _ReportDrillDownModalState();
}

class _ReportDrillDownModalState extends State<ReportDrillDownModal> {
  final _reportService = FinancialReportService();
  bool _isLoading = true;
  List<dynamic> _data = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> data;
      if (widget.category == AccountCategory.accountsReceivable) {
        data = await _reportService.getAccountsReceivableDetailed(
          widget.companyId,
        );
      } else if (widget.category == AccountCategory.accountsPayable) {
        data = await _reportService.getAccountsPayableDetailed(
          widget.companyId,
        );
      } else {
        // Default to General Ledger lines for this account
        data = await _reportService.getGeneralLedger(
          widget.companyId,
          widget.accountId,
          DateTime(DateTime.now().year, 1, 1),
          DateTime.now(),
          jobId: widget.jobId,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 1000,
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
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.accountCode,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.accountName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Account Drill-down / Detailed Statement',
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
                hintText: 'Search records...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export to Excel',
            onPressed: () {},
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
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No records found for this account'),
        ],
      ),
    );
  }

  Widget _buildTable(ThemeData theme) {
    if (widget.category == AccountCategory.accountsReceivable) {
      return _buildARTable(theme);
    } else if (widget.category == AccountCategory.accountsPayable) {
      return _buildAPTable(theme);
    } else {
      return _buildGLTable(theme);
    }
  }

  Widget _buildARTable(ThemeData theme) {
    final filtered = _data
        .where(
          (item) => item['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Customer Name')),
          DataColumn(label: Text('Invoices'), numeric: true),
          DataColumn(label: Text('Total Invoiced'), numeric: true),
          DataColumn(label: Text('Paid'), numeric: true),
          DataColumn(label: Text('Outstanding'), numeric: true),
        ],
        rows: filtered.map((item) {
          return DataRow(
            onSelectChanged: (_) =>
                _showCustomerLedger(item['id'], item['name']),
            cells: [
              DataCell(
                Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(item['invoiceCount'].toString())),
              DataCell(Text(AppFormatters.currency(item['totalInvoiced']))),
              DataCell(Text(AppFormatters.currency(item['totalPaid']))),
              DataCell(
                Text(
                  AppFormatters.currency(item['outstanding']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAPTable(ThemeData theme) {
    final filtered = _data
        .where(
          (item) => item['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Supplier Name')),
          DataColumn(label: Text('Bills'), numeric: true),
          DataColumn(label: Text('Total Billed'), numeric: true),
          DataColumn(label: Text('Paid'), numeric: true),
          DataColumn(label: Text('Outstanding'), numeric: true),
        ],
        rows: filtered.map((item) {
          return DataRow(
            onSelectChanged: (_) =>
                _showSupplierLedger(item['id'], item['name']),
            cells: [
              DataCell(
                Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(item['billCount'].toString())),
              DataCell(Text(AppFormatters.currency(item['totalBilled']))),
              DataCell(Text(AppFormatters.currency(item['totalPaid']))),
              DataCell(
                Text(
                  AppFormatters.currency(item['outstanding']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGLTable(ThemeData theme) {
    final filtered = _data
        .where(
          (item) =>
              item['description'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item['reference'].toString().toLowerCase().contains(
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
          DataColumn(label: Text('Debit'), numeric: true),
          DataColumn(label: Text('Credit'), numeric: true),
          DataColumn(label: Text('Balance'), numeric: true),
        ],
        rows: filtered.map((item) {
          final isOpening = item['description'] == 'Opening Balance';
          return DataRow(
            cells: [
              DataCell(Text(AppFormatters.date(item['date']))),
              DataCell(
                Text(
                  item['description'],
                  style: isOpening
                      ? const TextStyle(fontStyle: FontStyle.italic)
                      : null,
                ),
              ),
              DataCell(Text(item['reference'])),
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
                  AppFormatters.currency(item['balance']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showCustomerLedger(String id, String name) async {
    final ledger = await _reportService.getCustomerLedger(widget.companyId, id);
    if (!mounted) return;
    _showLedgerModal('Customer Ledger: $name', ledger);
  }

  void _showSupplierLedger(String id, String name) async {
    final ledger = await _reportService.getSupplierLedger(widget.companyId, id);
    if (!mounted) return;
    _showLedgerModal('Supplier Ledger: $name', ledger);
  }

  void _showLedgerModal(String title, List<Map<String, dynamic>> ledger) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(60),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Number')),
                      DataColumn(label: Text('Debit'), numeric: true),
                      DataColumn(label: Text('Credit'), numeric: true),
                      DataColumn(label: Text('Balance'), numeric: true),
                    ],
                    rows: ledger.map((entry) {
                      return DataRow(
                        cells: [
                          DataCell(Text(AppFormatters.date(entry['date']))),
                          DataCell(Text(entry['type'])),
                          DataCell(Text(entry['number'])),
                          DataCell(
                            Text(
                              entry['debit'] > 0
                                  ? AppFormatters.currency(entry['debit'])
                                  : '—',
                            ),
                          ),
                          DataCell(
                            Text(
                              entry['credit'] > 0
                                  ? AppFormatters.currency(entry['credit'])
                                  : '—',
                            ),
                          ),
                          DataCell(
                            Text(
                              AppFormatters.currency(entry['balance']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    double total = 0;
    if (widget.category == AccountCategory.accountsReceivable ||
        widget.category == AccountCategory.accountsPayable) {
      total = _data.fold(0.0, (sum, item) => sum + item['outstanding']);
    } else if (_data.isNotEmpty) {
      total = _data.last['balance'];
    }

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
            'TOTAL OUTSTANDING / BALANCE: ',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Text(
            AppFormatters.currency(total),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
