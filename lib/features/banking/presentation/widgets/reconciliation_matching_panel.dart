import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/models/bank_reconciliation_model.dart';
import 'package:ledgixerp/features/banking/services/bank_reconciliation_service.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';

class ReconciliationMatchingPanel extends StatefulWidget {
  final AppUser user;
  final BankAccountModel selectedAccount;
  final BankStatementEntry? selectedEntry;
  final VoidCallback onMatch;

  const ReconciliationMatchingPanel({
    super.key,
    required this.user,
    required this.selectedAccount,
    this.selectedEntry,
    required this.onMatch,
  });

  @override
  State<ReconciliationMatchingPanel> createState() =>
      _ReconciliationMatchingPanelState();
}

class _ReconciliationMatchingPanelState
    extends State<ReconciliationMatchingPanel> {
  final _reconService = BankReconciliationService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void didUpdateWidget(ReconciliationMatchingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedEntry != oldWidget.selectedEntry) {
      _fetchSuggestions();
    }
  }

  Future<void> _fetchSuggestions() async {
    if (widget.selectedEntry == null) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final matches = await _reconService.getPotentialMatches(
        companyId: widget.user.companyId!,
        linkedChartAccountId: widget.selectedAccount.linkedChartAccountId,
        entry: widget.selectedEntry!,
      );
      setState(() => _suggestions = matches);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedEntry == null) {
      return const Center(
        child: Text('Select a statement entry to find matches.'),
      );
    }

    final entry = widget.selectedEntry!;

    return Column(
      children: [
        _buildSelectionHeader(entry),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMatchesList(),
        ),
      ],
    );
  }

  Widget _buildSelectionHeader(BankStatementEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Matching for:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (entry.status == ReconciliationStatus.matched)
                TextButton.icon(
                  onPressed: () => _unmatch(entry),
                  icon: const Icon(Icons.link_off, size: 16),
                  label: const Text('Unmatch', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                )
              else
                TextButton.icon(
                  onPressed: () => _ignore(entry),
                  icon: const Icon(Icons.visibility_off, size: 16),
                  label: const Text('Ignore', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          Text(
            entry.description,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                DateFormat('MMM d, y').format(entry.date),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              Text(
                '${widget.selectedAccount.currency} ${NumberFormat('#,##0.00').format(entry.credit > 0 ? entry.credit : entry.debit)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    return Column(
      children: [
        if (_suggestions.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No automatic matches found.'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showManualSearch,
                    icon: const Icon(Icons.search),
                    label: const Text('Manual Search'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_suggestions.length} suggestions found',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showManualSearch,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text(
                    'Search More',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final match = _suggestions[index];
                final journal = match['transaction'] as JournalEntryModel;
                final score = match['matchScore'] as int;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildScoreBadge(score),
                            const SizedBox(width: 8),
                            Text(
                              journal.reference,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('MMM d, y').format(journal.date),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          journal.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Match found in Journal Entries',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _match(widget.selectedEntry!, journal),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Match'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _showManualSearch() {
    showDialog(
      context: context,
      builder: (context) => ManualSearchDialog(
        user: widget.user,
        selectedAccount: widget.selectedAccount,
        entry: widget.selectedEntry!,
        onSelect: (journal) {
          Navigator.pop(context);
          _match(widget.selectedEntry!, journal);
        },
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    Color color = score > 80
        ? Colors.green
        : (score > 50 ? Colors.orange : Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _match(
    BankStatementEntry entry,
    JournalEntryModel journal,
  ) async {
    setState(() => _isLoading = true);
    try {
      await _reconService.matchEntry(
        companyId: widget.user.companyId!,
        entryId: entry.id,
        transactionId: journal.id,
        transactionType: 'journal_entry',
        userId: widget.user.uid,
      );
      widget.onMatch();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unmatch(BankStatementEntry entry) async {
    setState(() => _isLoading = true);
    try {
      await _reconService.unmatchEntry(
        companyId: widget.user.companyId!,
        entryId: entry.id,
        userId: widget.user.uid,
      );
      widget.onMatch();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ignore(BankStatementEntry entry) async {
    await _reconService.ignoreEntry(widget.user.companyId!, entry.id);
    widget.onMatch();
  }
}

class ManualSearchDialog extends StatefulWidget {
  final AppUser user;
  final BankAccountModel selectedAccount;
  final BankStatementEntry entry;
  final Function(JournalEntryModel) onSelect;

  const ManualSearchDialog({
    super.key,
    required this.user,
    required this.selectedAccount,
    required this.entry,
    required this.onSelect,
  });

  @override
  State<ManualSearchDialog> createState() => _ManualSearchDialogState();
}

class _ManualSearchDialogState extends State<ManualSearchDialog> {
  final _reconService = BankReconciliationService();
  final _searchController = TextEditingController();
  List<JournalEntryModel> _results = [];
  bool _isLoading = false;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    // Default search with amount and +/- 30 days
    _dateRange = DateTimeRange(
      start: widget.entry.date.subtract(const Duration(days: 30)),
      end: widget.entry.date.add(const Duration(days: 30)),
    );
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final amount = widget.entry.credit > 0
          ? widget.entry.credit
          : widget.entry.debit;
      final results = await _reconService.searchTransactions(
        companyId: widget.user.companyId!,
        linkedChartAccountId: widget.selectedAccount.linkedChartAccountId,
        query: _searchController.text,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        amount: _searchController.text.isEmpty ? amount : null,
      );
      setState(() => _results = results);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manual ERP Transaction Search',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by reference or description...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() => _dateRange = picked);
                      _performSearch();
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dateRange == null
                        ? 'Date Range'
                        : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions found matching your criteria.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final journal = _results[index];

                        // Re-calculate the specific line amount for this account
                        final line = journal.lines.firstWhere(
                          (l) =>
                              l.accountId ==
                              widget.selectedAccount.linkedChartAccountId,
                        );
                        final lineAmount = line.debit > 0
                            ? line.debit
                            : line.credit;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  journal.reference,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${widget.selectedAccount.currency} ${NumberFormat('#,##0.00').format(lineAmount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(journal.description),
                                Text(
                                  DateFormat('MMM d, y').format(journal.date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => widget.onSelect(journal),
                              child: const Text('Select'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
