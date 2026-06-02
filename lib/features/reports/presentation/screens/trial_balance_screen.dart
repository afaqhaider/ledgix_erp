import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../services/reporting_service.dart';
import '../../models/report_models.dart';

class TrialBalanceScreen extends StatefulWidget {
  final AppUser user;
  const TrialBalanceScreen({super.key, required this.user});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final _reportingService = ReportingService();
  DateTime _selectedDate = DateTime.now();
  late Future<TrialBalanceReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = _reportingService.getTrialBalance(
        widget.user.companyId!,
        _selectedDate,
      );
    });
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
        title: const Text('Trial Balance'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReport),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implement PDF Export
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
            child: FutureBuilder<TrialBalanceReport>(
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

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      children: [
                        DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Account Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Code',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Debit',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Credit',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                          ],
                          rows: [
                            ...report.balances
                                .where((b) => b.debit != 0 || b.credit != 0)
                                .map(
                                  (b) => DataRow(
                                    cells: [
                                      DataCell(Text(b.account.accountName)),
                                      DataCell(Text(b.account.accountCode)),
                                      DataCell(
                                        Text(
                                          b.debit > 0
                                              ? currencyFormat.format(b.debit)
                                              : '',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          b.credit > 0
                                              ? currencyFormat.format(b.credit)
                                              : '',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            DataRow(
                              color: WidgetStateProperty.all(
                                Colors.grey.withValues(alpha: 0.1),
                              ),
                              cells: [
                                const DataCell(
                                  Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const DataCell(Text('')),
                                DataCell(
                                  Text(
                                    currencyFormat.format(report.totalDebits),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    currencyFormat.format(report.totalCredits),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if ((report.totalDebits - report.totalCredits).abs() >
                            0.01)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Unbalanced! Difference: ${currencyFormat.format(report.totalDebits - report.totalCredits)}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
