import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import '../../services/reporting_service.dart';
import '../../models/report_models.dart';
import 'package:ledgixerp/core/services/export_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';

class ProfitLossScreen extends StatefulWidget {
  final AppUser user;
  const ProfitLossScreen({super.key, required this.user});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  final _reportingService = ReportingService();
  final _exportService = ExportService();
  final _companyService = CompanyService();
  CompanyModel? _company;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  late Future<ProfitLossReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReport();
    _loadCompany();
  }

  void _loadCompany() {
    _companyService.getCompany(widget.user.companyId!).listen((company) {
      if (mounted) setState(() => _company = company);
    });
  }

  void _loadReport() {
    setState(() {
      _reportFuture = _reportingService.getProfitLoss(
        widget.user.companyId!,
        _startDate,
        _endDate,
      );
    });
  }

  Future<void> _exportReport(ProfitLossReport report, bool isPdf) async {
    final currencySymbol = _company?.baseCurrency ?? 'AED';
    final dateRange = '${AppFormatters.date(_startDate)} - ${AppFormatters.date(_endDate)}';

    if (isPdf) {
      final List<List<String>> tableData = [];
      
      tableData.add(['INCOME', '']);
      for (var b in report.income) {
        tableData.add([b.account.accountName, AppFormatters.currency(b.balance, symbol: currencySymbol)]);
      }
      tableData.add(['Total Income', AppFormatters.currency(report.totalIncome, symbol: currencySymbol)]);
      tableData.add(['', '']);

      tableData.add(['COST OF SALES', '']);
      for (var b in report.costOfSales) {
        tableData.add([b.account.accountName, AppFormatters.currency(b.balance, symbol: currencySymbol)]);
      }
      tableData.add(['Total Cost of Sales', AppFormatters.currency(report.totalCostOfSales, symbol: currencySymbol)]);
      tableData.add(['', '']);

      tableData.add(['GROSS PROFIT', AppFormatters.currency(report.grossProfit, symbol: currencySymbol)]);
      tableData.add(['', '']);

      tableData.add(['EXPENSES', '']);
      for (var b in report.expenses) {
        tableData.add([b.account.accountName, AppFormatters.currency(b.balance, symbol: currencySymbol)]);
      }
      tableData.add(['Total Expenses', AppFormatters.currency(report.totalExpenses, symbol: currencySymbol)]);
      tableData.add(['', '']);

      tableData.add(['NET PROFIT', AppFormatters.currency(report.netProfit, symbol: currencySymbol)]);

      await _exportService.exportReportToPdf(
        title: 'Profit & Loss Report',
        subTitle: 'Period: $dateRange',
        headers: ['Account', 'Amount'],
        data: tableData,
      );
    } else {
      final List<List<dynamic>> excelData = [];
      excelData.add(['Account', 'Amount']);
      
      excelData.add(['INCOME']);
      for (var b in report.income) {
        excelData.add([b.account.accountName, b.balance]);
      }
      excelData.add(['Total Income', report.totalIncome]);
      excelData.add([]);

      excelData.add(['COST OF SALES']);
      for (var b in report.costOfSales) {
        excelData.add([b.account.accountName, b.balance]);
      }
      excelData.add(['Total Cost of Sales', report.totalCostOfSales]);
      excelData.add([]);

      excelData.add(['GROSS PROFIT', report.grossProfit]);
      excelData.add([]);

      excelData.add(['EXPENSES']);
      for (var b in report.expenses) {
        excelData.add([b.account.accountName, b.balance]);
      }
      excelData.add(['Total Expenses', report.totalExpenses]);
      excelData.add([]);

      excelData.add(['NET PROFIT', report.netProfit]);

      await _exportService.exportToExcel(
        fileName: 'Profit_and_Loss_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}',
        sheetName: 'Profit & Loss',
        headers: ['Statement of Profit & Loss', dateRange],
        data: excelData,
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReport),
          FutureBuilder<ProfitLossReport>(
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
            child: InkWell(
              onTap: () => _selectDateRange(context),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Period: ${AppFormatters.date(_startDate)} - ${AppFormatters.date(_endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 16),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<ProfitLossReport>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final report = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection('INCOME', report.income),
                    _buildTotalRow(
                      'Total Income',
                      report.totalIncome,
                      isBold: true,
                    ),
                    const Divider(height: 32),

                    _buildSection(
                      'COST OF SALES',
                      report.costOfSales,
                    ),
                    _buildTotalRow(
                      'Total Cost of Sales',
                      report.totalCostOfSales,
                      isBold: true,
                    ),
                    const Divider(height: 32),

                    _buildTotalRow(
                      'GROSS PROFIT',
                      report.grossProfit,
                      isHeader: true,
                    ),
                    const SizedBox(height: 24),

                    _buildSection('EXPENSES', report.expenses),
                    _buildTotalRow(
                      'Total Expenses',
                      report.totalExpenses,
                      isBold: true,
                    ),
                    const Divider(height: 48),

                    _buildTotalRow(
                      'NET PROFIT',
                      report.netProfit,
                      isHeader: true,
                      highlight: true,
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
        ...balances.map(
          (b) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(b.account.accountName),
                Text(AppFormatters.currency(b.balance, symbol: _company?.baseCurrency)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String title,
    double amount, {
    bool isBold = false,
    bool isHeader = false,
    bool highlight = false,
  }) {
    final currencySymbol = _company?.baseCurrency ?? 'AED';
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
            AppFormatters.currency(amount, symbol: currencySymbol),
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
