import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/models/bank_reconciliation_model.dart';
import 'package:ledgixerp/features/banking/services/bank_account_service.dart';
import 'package:ledgixerp/features/banking/services/bank_reconciliation_service.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';
import 'package:ledgixerp/features/banking/presentation/widgets/import_statement_dialog.dart';
import 'package:ledgixerp/features/banking/presentation/widgets/reconciliation_matching_panel.dart';

class BankReconciliationScreen extends StatefulWidget {
  final AppUser user;
  const BankReconciliationScreen({super.key, required this.user});

  @override
  State<BankReconciliationScreen> createState() =>
      _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends State<BankReconciliationScreen> {
  final _bankService = BankAccountService();
  final _reconService = BankReconciliationService();

  BankAccountModel? _selectedAccount;
  DateTimeRange? _dateRange;
  ReconciliationStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Reconciliation'),
        actions: [
          if (_selectedAccount != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showImportDialog(),
                icon: const Icon(Icons.upload_file),
                label: const Text('Import Statement'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(
            child: _selectedAccount == null
                ? const Center(
                    child: Text(
                      'Please select a bank account to begin reconciliation.',
                    ),
                  )
                : _buildReconciliationView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<List<BankAccountModel>>(
              stream: _bankService.getBankAccounts(widget.user.companyId!),
              builder: (context, snapshot) {
                final accounts = snapshot.data ?? [];
                return DropdownButtonFormField<BankAccountModel>(
                  value: _selectedAccount,
                  decoration: const InputDecoration(
                    labelText: 'Select Bank Account',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (acc) => DropdownMenuItem(
                          value: acc,
                          child: Text('${acc.accountName} (${acc.currency})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedAccount = val),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  initialDateRange: _dateRange,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dateRange = picked);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                _dateRange == null
                    ? 'Select Date Range'
                    : '${DateFormat('MMM d, y').format(_dateRange!.start)} - ${DateFormat('MMM d, y').format(_dateRange!.end)}',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<ReconciliationStatus?>(
              value: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Match Status',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...ReconciliationStatus.values.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _statusFilter = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationView() {
    return StreamBuilder<List<BankStatementEntry>>(
      stream: _reconService.getStatementEntries(
        companyId: widget.user.companyId!,
        bankAccountId: _selectedAccount!.id,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        status: _statusFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return const Center(
            child: Text('No statement entries found for the selected filters.'),
          );
        }

        return Column(
          children: [
            _buildSummaryHeader(entries),
            Expanded(
              child: Row(
                children: [
                  // Left: Bank Statement Panel
                  Expanded(flex: 1, child: _buildStatementPanel(entries)),
                  const VerticalDivider(width: 1),
                  // Right: ERP Transactions / Matching Panel
                  Expanded(
                    flex: 1,
                    child: ReconciliationMatchingPanel(
                      user: widget.user,
                      selectedAccount: _selectedAccount!,
                      selectedEntry: _selectedEntry,
                      onMatch: () => setState(() => _selectedEntry = null),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  BankStatementEntry? _selectedEntry;

  Widget _buildSummaryHeader(List<BankStatementEntry> entries) {
    double statementBalance = entries.isNotEmpty ? entries.first.balance : 0;
    double erpBalance = _selectedAccount?.currentBalance ?? 0;
    double diff = statementBalance - erpBalance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Statement Balance', statementBalance),
          _buildSummaryItem('ERP Balance', erpBalance),
          _buildSummaryItem(
            'Difference',
            diff,
            color: diff == 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          '${_selectedAccount?.currency} ${NumberFormat('#,##0.00').format(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatementPanel(List<BankStatementEntry> entries) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = _selectedEntry?.id == entry.id;

        return ListTile(
          selected: isSelected,
          onTap: () => setState(() => _selectedEntry = entry),
          title: Row(
            children: [
              Text(
                DateFormat('MMM d').format(entry.date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.description,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              if (entry.reference != null)
                Text(
                  entry.reference!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              const Spacer(),
              _buildStatusBadge(entry.status),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (entry.credit > 0)
                Text(
                  '+${NumberFormat('#,##0.00').format(entry.credit)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (entry.debit > 0)
                Text(
                  '-${NumberFormat('#,##0.00').format(entry.debit)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                'Bal: ${NumberFormat('#,##0.00').format(entry.balance)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ReconciliationStatus status) {
    Color color;
    switch (status) {
      case ReconciliationStatus.matched:
        color = Colors.green;
        break;
      case ReconciliationStatus.unmatched:
        color = Colors.orange;
        break;
      case ReconciliationStatus.partial:
        color = Colors.blue;
        break;
      case ReconciliationStatus.ignored:
        color = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => ImportStatementDialog(
        companyId: widget.user.companyId!,
        bankAccountId: _selectedAccount!.id,
      ),
    );
  }
}
