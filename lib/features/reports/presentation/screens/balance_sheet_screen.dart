import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../services/reporting_service.dart';
import '../../models/report_models.dart';
import 'package:ledgixerp/core/services/export_service.dart';

class BalanceSheetScreen extends StatefulWidget {
  final AppUser user;
  const BalanceSheetScreen({super.key, required this.user});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  final _reportingService = ReportingService();
  final _exportService = ExportService();
  DateTime _selectedDate = DateTime.now();
  late Future<BalanceSheetReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = _reportingService.getBalanceSheet(
        widget.user.companyId!,
        _selectedDate,
      );
    });
  }

  Future<void> _exportReport(BalanceSheetReport report, bool isPdf) async {
    final currencyFormat = NumberFormat.simpleCurrency();
    final asOfDate = 'As of ${DateFormat('dd MMM yyyy').format(_selectedDate)}';

    if (isPdf) {
      final List<List<String>> tableData = [];
      
      tableData.add(['ASSETS', '']);
      for (var b in report.assets) {
        if (b.balance != 0) tableData.add([b.account.accountName, currencyFormat.format(b.balance)]);
      }
      tableData.add(['Total Assets', currencyFormat.format(report.totalAssets)]);
      tableData.add(['', '']);

      tableData.add(['LIABILITIES', '']);
      for (var b in report.liabilities) {
        if (b.balance != 0) tableData.add([b.account.accountName, currencyFormat.format(b.balance)]);
      }
      tableData.add(['Total Liabilities', currencyFormat.format(report.totalLiabilities)]);
      tableData.add(['', '']);

      tableData.add(['EQUITY', '']);
      for (var b in report.equity) {
        if (b.balance != 0) tableData.add([b.account.accountName, currencyFormat.format(b.balance)]);
      }
      tableData.add(['Net Profit Period', currencyFormat.format(report.netProfitPeriod)]);
      tableData.add(['Total Equity', currencyFormat.format(report.totalEquity)]);
      tableData.add(['', '']);

      tableData.add(['TOTAL LIABILITIES & EQUITY', currencyFormat.format(report.totalLiabilitiesAndEquity)]);

      await _exportService.exportReportToPdf(
        title: 'Balance Sheet Report',
        subTitle: asOfDate,
        headers: ['Category / Account', 'Amount'],
        data: tableData,
      );
    } else {
      final List<List<dynamic>> excelData = [];
      excelData.add(['Category / Account', 'Amount']);
      
      excelData.add(['ASSETS']);
      for (var b in report.assets) {
        if (b.balance != 0) excelData.add([b.account.accountName, b.balance]);
      }
      excelData.add(['Total Assets', report.totalAssets]);
      excelData.add([]);

      excelData.add(['LIABILITIES']);
      for (var b in report.liabilities) {
        if (b.balance != 0) excelData.add([b.account.accountName, b.balance]);
      }
      excelData.add(['Total Liabilities', report.totalLiabilities]);
      excelData.add([]);

      excelData.add(['EQUITY']);
      for (var b in report.equity) {
        if (b.balance != 0) excelData.add([b.account.accountName, b.balance]);
      }
      excelData.add(['Net Profit Period', report.netProfitPeriod]);
      excelData.add(['Total Equity', report.totalEquity]);
      excelData.add([]);

      excelData.add(['TOTAL LIABILITIES & EQUITY', report.totalLiabilitiesAndEquity]);

      await _exportService.exportToExcel(
        fileName: 'Balance_Sheet_${DateFormat('yyyyMMdd').format(_selectedDate)}',
        sheetName: 'Balance Sheet',
        headers: ['Account', 'Amount'],
        data: excelData,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Sheet'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReport),
          FutureBuilder<BalanceSheetReport>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.download),
                  onSelected: (value) => _exportReport(snapshot.data!, value == 'pdf'),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                    const PopupMenuItem(value: 'excel', child: Text('Export Excel')),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'As of:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<BalanceSheetReport>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final report = snapshot.data!;
                final currencyFormat = NumberFormat.simpleCurrency();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection('ASSETS', report.assets, currencyFormat),
                    _buildTotalRow(
                      'Total Assets',
                      report.totalAssets,
                      currencyFormat,
                      isBold: true,
                      highlight: true,
                    ),
                    const SizedBox(height: 32),

                    _buildSection(
                      'LIABILITIES',
                      report.liabilities,
                      currencyFormat,
                    ),
                    _buildTotalRow(
                      'Total Liabilities',
                      report.totalLiabilities,
                      currencyFormat,
                      isBold: true,
                    ),
                    const SizedBox(height: 24),

                    _buildEquitySection(report, currencyFormat),
                    _buildTotalRow(
                      'Total Equity',
                      report.totalEquity,
                      currencyFormat,
                      isBold: true,
                    ),
                    const Divider(height: 48),

                    _buildTotalRow(
                      'TOTAL LIABILITIES & EQUITY',
                      report.totalLiabilitiesAndEquity,
                      currencyFormat,
                      isHeader: true,
                      highlight: true,
                    ),

                    if ((report.totalAssets - report.totalLiabilitiesAndEquity)
                            .abs() >
                        0.01)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Note: Balance sheet is not balanced. Check your journal entries.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<AccountBalance> balances,
    NumberFormat format,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ...balances
            .where((b) => b.balance != 0)
            .map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.account.accountName),
                    Text(format.format(b.balance)),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildEquitySection(BalanceSheetReport report, NumberFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EQUITY',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ...report.equity
            .where((b) => b.balance != 0)
            .map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.account.accountName),
                    Text(format.format(b.balance)),
                  ],
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Profit for Period',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              Text(format.format(report.netProfitPeriod)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String title,
    double amount,
    NumberFormat format, {
    bool isBold = false,
    bool isHeader = false,
    bool highlight = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isHeader ? 12 : 8, horizontal: 8),
      decoration: highlight
          ? BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: (isBold || isHeader)
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: isHeader ? 18 : 14,
            ),
          ),
          Text(
            format.format(amount),
            style: TextStyle(
              fontWeight: (isBold || isHeader)
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: isHeader ? 18 : 14,
              color: amount < 0 ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
