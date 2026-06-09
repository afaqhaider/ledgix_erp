import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import '../../services/financial_report_service.dart';

import 'package:google_fonts/google_fonts.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(theme),
        _buildFilters(theme, isDark),
        if (_selectedAccount != null && !_isLoading && _entries.isNotEmpty)
          _buildSummary(theme),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedAccount == null
              ? _buildEmptyState(
                  theme,
                  'Please select an account',
                  Icons.account_tree_outlined,
                )
              : _entries.isEmpty
              ? _buildEmptyState(
                  theme,
                  'No entries found for the selected period',
                  Icons.search_off_rounded,
                )
              : _buildStatementTable(theme, isDark),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Statement',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Formal statement of account for customers, suppliers, or ledger',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Statement',
            onPressed: _selectedAccount != null ? _loadEntries : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export PDF',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('companies')
                .doc(widget.companyId)
                .collection('chartOfAccounts')
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
                  prefixIcon: Icon(Icons.account_tree_outlined, size: 20),
                  isDense: true,
                ),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a,
                        child: Text(
                          '${a.accountCode} - ${a.accountName}',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
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
                      labelText: 'Reporting Period',
                      prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
                      isDense: true,
                    ),
                    child: Text(
                      '${AppFormatters.date(_startDate)} — ${AppFormatters.date(_endDate)}',
                      style: GoogleFonts.inter(fontSize: 14),
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

  Widget _buildSummary(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(theme, 'Opening Balance', _openingBalance),
          _summaryItem(theme, 'Total Debit', _totalDebit),
          _summaryItem(theme, 'Total Credit', _totalCredit),
          _summaryItem(
            theme,
            'Closing Balance',
            _closingBalance,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    ThemeData theme,
    String label,
    double amount, {
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppFormatters.currency(amount),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
            color: isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatementTable(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DataTable(
            headingRowHeight: 48,
            columnSpacing: 32,
            headingRowColor: WidgetStateProperty.all(
              isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
            ),
            columns: [
              _buildColumn('Date'),
              _buildColumn('Description'),
              _buildColumn('Ref'),
              _buildColumn('Debit', numeric: true),
              _buildColumn('Credit', numeric: true),
              _buildColumn('Balance', numeric: true),
            ],
            rows: _entries.map((e) {
              final debit = (e['debit'] as num).toDouble();
              final credit = (e['credit'] as num).toDouble();
              final balance = (e['balance'] as num).toDouble();
              final isOpening = e['description'] == 'Opening Balance';

              return DataRow(
                color: isOpening
                    ? WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                      )
                    : null,
                cells: [
                  DataCell(
                    Text(
                      AppFormatters.date(e['date'] as DateTime),
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 250,
                      child: Text(
                        e['description'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontStyle: isOpening ? FontStyle.italic : null,
                          fontWeight: isOpening
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      e['reference'] ?? '—',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                  DataCell(
                    Text(
                      debit > 0 ? AppFormatters.currency(debit) : '—',
                      style: GoogleFonts.jetBrainsMono(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    Text(
                      credit > 0 ? AppFormatters.currency(credit) : '—',
                      style: GoogleFonts.jetBrainsMono(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    Text(
                      AppFormatters.currency(balance),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: isOpening
                            ? FontWeight.w600
                            : FontWeight.w800,
                        color: isOpening
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _buildColumn(String label, {bool numeric = false}) {
    return DataColumn(
      numeric: numeric,
      label: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
