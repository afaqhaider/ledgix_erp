import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import '../../services/financial_report_service.dart';

import 'package:google_fonts/google_fonts.dart';

class GeneralLedgerScreen extends StatefulWidget {
  final String companyId;
  const GeneralLedgerScreen({super.key, required this.companyId});

  @override
  State<GeneralLedgerScreen> createState() => _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends State<GeneralLedgerScreen> {
  final _reportService = FinancialReportService();
  final _firestore = FirebaseFirestore.instance;

  AccountModel? _selectedAccount;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;

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
      setState(() => _entries = entries);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading ledger: $e')));
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
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selectedAccount == null
              ? _buildEmptyState(
                theme,
                'Please select an account to view the ledger',
                Icons.account_tree_outlined,
              )
              : _entries.isEmpty
              ? _buildEmptyState(
                theme,
                'No entries found for the selected period',
                Icons.search_off_rounded,
              )
              : _buildLedgerTable(theme, isDark),
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
                  'General Ledger',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Detailed transaction history for specific accounts',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Ledger',
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

  Widget _buildLedgerTable(ThemeData theme, bool isDark) {
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
              final debit = e['debit'] as double;
              final credit = e['credit'] as double;
              final balance = e['balance'] as double;
              final isOpening = e['description'] == 'Opening Balance';

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      AppFormatters.date(e['date'] as DateTime),
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 300,
                      child: Text(
                        e['description'] ?? '',
                        style: GoogleFonts.inter(fontSize: 13),
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
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      credit > 0 ? AppFormatters.currency(credit) : '—',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      AppFormatters.currency(balance),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: isOpening
                            ? FontWeight.w500
                            : FontWeight.w800,
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
