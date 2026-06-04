import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/core/theme/app_text_styles.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import '../../services/financial_report_service.dart';

class AccountStatementScreen extends StatefulWidget {
  final String companyId;
  const AccountStatementScreen({super.key, required this.companyId});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  final _reportService = FinancialReportService();
  final _firestore = FirebaseFirestore.instance;

  AccountModel? _selectedAccount;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;

  double _openingBalance = 0;
  double _totalDebit = 0;
  double _totalCredit = 0;
  double _closingBalance = 0;

  Future<void> _loadEntries() async {
    if (_selectedAccount == null) return;

    setState(() => _isLoading = true);
    try {
      final entries = await _reportService.getGeneralLedger(
        widget.companyId,
        _selectedAccount!.id,
        _startDate,
        _endDate,
      );

      double totalDebit = 0;
      double totalCredit = 0;
      double openingBal = 0;

      if (entries.isNotEmpty) {
        openingBal = entries.first['balance'];
        for (var i = 1; i < entries.length; i++) {
          totalDebit += (entries[i]['debit'] as num).toDouble();
          totalCredit += (entries[i]['credit'] as num).toDouble();
        }
      }

      setState(() {
        _entries = entries;
        _openingBalance = openingBal;
        _totalDebit = totalDebit;
        _totalCredit = totalCredit;
        _closingBalance = entries.isNotEmpty
            ? (entries.last['balance'] as num).toDouble()
            : 0;
      });
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Statement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selectedAccount != null ? _loadEntries : null,
          ),
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          if (_selectedAccount != null && !_isLoading && _entries.isNotEmpty)
            _buildSummary(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedAccount == null
                ? const Center(child: Text('Please select an account.'))
                : _entries.isEmpty
                ? const Center(child: Text('No entries found.'))
                : _buildStatementTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('companies')
                .doc(widget.companyId)
                .collection('accounts')
                .where('isActive', isEqualTo: true)
                .where('allowPosting', isEqualTo: true)
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

              accounts.sort((a, b) => a.accountCode.compareTo(b.accountCode));

              return DropdownButtonFormField<AccountModel>(
                initialValue: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'Select Account',
                  prefixIcon: Icon(Icons.account_tree_outlined),
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
          const SizedBox(height: AppSpacing.md),
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
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Text(
                      '${AppFormatters.date(_startDate)} - ${AppFormatters.date(_endDate)}',
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

  Widget _buildSummary() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Opening', _openingBalance),
          _summaryItem('Total Debit', _totalDebit),
          _summaryItem('Total Credit', _totalCredit),
          _summaryItem('Closing', _closingBalance, isPrimary: true),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, {bool isPrimary = false}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppFormatters.currency(amount),
          style: AppTextStyles.amount.copyWith(
            fontSize: 16,
            color: isPrimary ? theme.colorScheme.primary : null,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatementTable() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 32,
          headingRowHeight: 40,
          columns: [
            const DataColumn(label: Text('Date')),
            const DataColumn(label: Text('Description')),
            const DataColumn(label: Text('Ref')),
            DataColumn(
              label: Container(
                width: 90,
                alignment: Alignment.centerRight,
                child: const Text('Debit'),
              ),
            ),
            DataColumn(
              label: Container(
                width: 90,
                alignment: Alignment.centerRight,
                child: const Text('Credit'),
              ),
            ),
            DataColumn(
              label: Container(
                width: 100,
                alignment: Alignment.centerRight,
                child: const Text('Balance'),
              ),
            ),
          ],
          rows: _entries.map((e) {
            final debit = (e['debit'] as num).toDouble();
            final credit = (e['credit'] as num).toDouble();
            final balance = (e['balance'] as num).toDouble();
            final isOpening = e['description'] == 'Opening Balance';

            return DataRow(
              color: isOpening
                  ? WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    )
                  : null,
              cells: [
                DataCell(Text(AppFormatters.date(e['date'] as DateTime))),
                DataCell(
                  SizedBox(
                    width: 250,
                    child: Text(
                      e['description'] ?? '',
                      style: TextStyle(
                        fontStyle: isOpening ? FontStyle.italic : null,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(e['reference'] ?? '')),
                DataCell(
                  Container(
                    width: 90,
                    alignment: Alignment.centerRight,
                    child: Text(
                      debit > 0 ? AppFormatters.currency(debit) : '',
                      style: AppTextStyles.amount,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    width: 90,
                    alignment: Alignment.centerRight,
                    child: Text(
                      credit > 0 ? AppFormatters.currency(credit) : '',
                      style: AppTextStyles.amount,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    width: 100,
                    alignment: Alignment.centerRight,
                    child: Text(
                      AppFormatters.currency(balance),
                      style: AppTextStyles.amount.copyWith(
                        fontWeight: isOpening
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
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
