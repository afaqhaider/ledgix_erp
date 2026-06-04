import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../services/reporting_service.dart';
import '../../../accounting/chart_of_accounts/account_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeneralLedgerScreen extends StatefulWidget {
  final AppUser user;
  const GeneralLedgerScreen({super.key, required this.user});

  @override
  State<GeneralLedgerScreen> createState() => _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends State<GeneralLedgerScreen> {
  final _reportingService = ReportingService();
  final _firestore = FirebaseFirestore.instance;

  AccountModel? _selectedAccount;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadEntries() async {
    if (_selectedAccount == null) return;

    setState(() => _isLoading = true);
    try {
      final entries = await _reportingService.getLedgerEntries(
        widget.user.companyId!,
        _selectedAccount!.id,
        _startDate,
        _endDate,
      );
      setState(() => _entries = entries);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('General Ledger')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                ? const Center(
                    child: Text('No entries found for the selected criteria.'),
                  )
                : _buildLedgerTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('accounts')
                .where('companyId', isEqualTo: widget.user.companyId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final accounts = snapshot.data!.docs
                  .map(
                    (doc) => AccountModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

              return DropdownButtonFormField<AccountModel>(
                initialValue: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'Select Account',
                  border: OutlineInputBorder(),
                ),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: Text('${a.accountCode} - ${a.accountName}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedAccount = v);
                  _loadEntries();
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: DateTimeRange(
                        start: _startDate,
                        end: _endDate,
                      ),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _loadEntries();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Period',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTable() {
    final currencyFormat = NumberFormat.simpleCurrency();
    double runningBalance = 0; // Ideally should start with opening balance

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Ref')),
            DataColumn(
              label: Text('Debit', textAlign: TextAlign.right),
              numeric: true,
            ),
            DataColumn(
              label: Text('Credit', textAlign: TextAlign.right),
              numeric: true,
            ),
            DataColumn(
              label: Text('Balance', textAlign: TextAlign.right),
              numeric: true,
            ),
          ],
          rows: _entries.map((e) {
            final debit = e['debit'] as double;
            final credit = e['credit'] as double;

            // Adjust balance based on account type
            if (_selectedAccount!.accountType == AccountType.asset ||
                _selectedAccount!.accountType == AccountType.expense ||
                _selectedAccount!.accountType == AccountType.costOfSales) {
              runningBalance += (debit - credit);
            } else {
              runningBalance += (credit - debit);
            }

            return DataRow(
              cells: [
                DataCell(
                  Text(DateFormat('dd MMM yy').format(e['date'] as DateTime)),
                ),
                DataCell(Text(e['description'] ?? '')),
                DataCell(Text(e['reference'] ?? '')),
                DataCell(Text(debit > 0 ? currencyFormat.format(debit) : '')),
                DataCell(Text(credit > 0 ? currencyFormat.format(credit) : '')),
                DataCell(
                  Text(
                    currencyFormat.format(runningBalance),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
