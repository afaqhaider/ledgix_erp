import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/services/journal_service.dart';
import 'package:ledgixerp/features/accounting/journal/presentation/screens/journal_entry_detail_screen.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

import 'package:ledgixerp/features/accounting/journal/presentation/screens/create_journal_entry_screen.dart';

class AccountLedgerScreen extends StatefulWidget {
  final String accountId;
  final String accountName;
  final AppUser user;

  const AccountLedgerScreen({
    super.key,
    required this.accountId,
    required this.accountName,
    required this.user,
  });

  @override
  State<AccountLedgerScreen> createState() => _AccountLedgerScreenState();
}

class _AccountLedgerScreenState extends State<AccountLedgerScreen> {
  final _journalService = JournalService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ledger: ${widget.accountName}'),
      ),
      body: VoucherListPage<JournalEntryModel>(
        title: widget.accountName,
        subtitle: 'Detailed transaction history for this account',
        stream: _journalService.getJournalEntriesByAccount(
          widget.user.companyId!,
          widget.accountId,
        ),
        onAddNew: () {
           // Maybe navigate to create journal with this account pre-selected?
           // For now, just show a message.
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Use Journal Entries to add new records.'))
           );
        },
        columns: const [
          'Date',
          'Reference',
          'Description',
          'Debit',
          'Credit',
          'Status',
          'Actions',
        ],
        emptyTitle: 'No transactions found',
        emptyMessage: 'There are no journal entries linked to this account.',
        rowBuilder: (entry, index) {
          // Find the lines for THIS account
          final lines = entry.lines.where((l) => l.accountId == widget.accountId).toList();
          final debit = lines.fold(0.0, (sum, l) => sum + l.debit);
          final credit = lines.fold(0.0, (sum, l) => sum + l.credit);

          return DataRow(
            cells: [
              DataCell(Text(AppFormatters.date(entry.date))),
              DataCell(Text(entry.reference,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(entry.description)),
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    debit > 0 ? AppFormatters.currency(debit) : '-',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ),
              DataCell(
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    credit > 0 ? AppFormatters.currency(credit) : '-',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              DataCell(ERPStatusBadge.fromStatus(entry.status.name)),
              DataCell(
                VoucherActionMenu(
                  onView: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalEntryDetailScreen(
                          entry: entry,
                          user: widget.user,
                        ),
                      ),
                    );
                  },
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateJournalEntryScreen(
                          user: widget.user,
                          entry: entry,
                        ),
                      ),
                    );
                  },
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (innerContext) => ERPConfirmDeleteDialog(
                        title: 'Delete Journal Entry',
                        message:
                            'Are you sure you want to delete entry ${entry.reference}?',
                        onConfirm: () async {
                          try {
                            await _journalService.deleteJournalEntry(
                                widget.user.companyId!, entry.id);
                          } catch (e) {
                            if (context.mounted) {
                              showErpError(context: context, error: e);
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
