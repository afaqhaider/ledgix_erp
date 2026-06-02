import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../services/reporting_service.dart';
import '../../models/report_models.dart';

class ProfitLossScreen extends StatefulWidget {
  final AppUser user;
  const ProfitLossScreen({super.key, required this.user});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  final _reportingService = ReportingService();
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  late Future<ProfitLossReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReport();
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
          IconButton(icon: const Icon(Icons.print), onPressed: () {}),
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
                    'Period: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
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
                final currencyFormat = NumberFormat.simpleCurrency();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection('INCOME', report.income, currencyFormat),
                    _buildTotalRow(
                      'Total Income',
                      report.totalIncome,
                      currencyFormat,
                      isBold: true,
                    ),
                    const Divider(height: 32),

                    _buildSection(
                      'COST OF SALES',
                      report.costOfSales,
                      currencyFormat,
                    ),
                    _buildTotalRow(
                      'Total Cost of Sales',
                      report.totalCostOfSales,
                      currencyFormat,
                      isBold: true,
                    ),
                    const Divider(height: 32),

                    _buildTotalRow(
                      'GROSS PROFIT',
                      report.grossProfit,
                      currencyFormat,
                      isHeader: true,
                    ),
                    const SizedBox(height: 24),

                    _buildSection('EXPENSES', report.expenses, currencyFormat),
                    _buildTotalRow(
                      'Total Expenses',
                      report.totalExpenses,
                      currencyFormat,
                      isBold: true,
                    ),
                    const Divider(height: 48),

                    _buildTotalRow(
                      'NET PROFIT',
                      report.netProfit,
                      currencyFormat,
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
        ...balances.map(
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
