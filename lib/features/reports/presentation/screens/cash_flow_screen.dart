import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/features/reports/services/cash_flow_service.dart';

class CashFlowScreen extends StatefulWidget {
  final String companyId;

  const CashFlowScreen({super.key, required this.companyId});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  final _service = CashFlowService();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  late Future<CashFlowData> _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = _service.getCashFlowReport(
        widget.companyId,
        _dateRange.start,
        _dateRange.end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow Statement'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text('${DateFormat('MMM dd').format(_dateRange.start)} - ${DateFormat('MMM dd').format(_dateRange.end)}'),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                initialDateRange: _dateRange,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (range != null) {
                setState(() => _dateRange = range);
                _loadReport();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<CashFlowData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionHeader('Cash flows from operating activities'),
              _buildRow('Net cash from operating activities', data.operatingActivities, isIndented: true),
              const SizedBox(height: 16),
              
              _buildSectionHeader('Cash flows from investing activities'),
              _buildRow('Net cash from investing activities', data.investingActivities, isIndented: true),
              const SizedBox(height: 16),
              
              _buildSectionHeader('Cash flows from financing activities'),
              _buildRow('Net cash from financing activities', data.financingActivities, isIndented: true),
              
              const Divider(height: 48),
              _buildRow('Net increase/decrease in cash', data.netCashIncrease, isBold: true),
              _buildRow('Cash at beginning of period', data.openingCash),
              const Divider(),
              _buildRow('Cash at end of period', data.closingCash, isBold: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildRow(String label, double amount, {bool isIndented = false, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isIndented ? 16.0 : 0.0, top: 4.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null)),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              color: amount < 0 ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
