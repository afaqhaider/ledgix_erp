import 'package:flutter/material.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import '../../models/report_models.dart';
import '../../services/financial_report_service.dart';

class TrialBalanceScreen extends StatefulWidget {
  final String companyId;

  const TrialBalanceScreen({super.key, required this.companyId});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final _reportService = FinancialReportService();
  DateTime _asOfDate = DateTime.now();
  TrialBalanceReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final report = await _reportService.getTrialBalance(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trial Balance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
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
          ),
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: theme.colorScheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'As of: ${AppFormatters.date(_asOfDate)}',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (_report != null && !_report!.isBalanced)
                        const Chip(
                          label: Text('OUT OF BALANCE'),
                          backgroundColor: Colors.red,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Code')),
                        DataColumn(label: Text('Account Name')),
                        DataColumn(label: Text('Debit'), numeric: true),
                        DataColumn(label: Text('Credit'), numeric: true),
                      ],
                      rows:
                          _report?.lines.map((l) {
                            return DataRow(
                              cells: [
                                DataCell(Text(l.code)),
                                DataCell(Text(l.name)),
                                DataCell(
                                  Text(
                                    l.debit > 0
                                        ? AppFormatters.currency(l.debit)
                                        : '',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    l.credit > 0
                                        ? AppFormatters.currency(l.credit)
                                        : '',
                                  ),
                                ),
                              ],
                            );
                          }).toList() ??
                          [],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      const Text(
                        'Total: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        AppFormatters.currency(_report?.totalDebit ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Text(
                        AppFormatters.currency(_report?.totalCredit ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
