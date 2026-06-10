import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/services/journal_service.dart';
import 'package:ledgixerp/features/accounting/journal/presentation/screens/create_journal_entry_screen.dart';
import 'package:ledgixerp/core/widgets/voucher_list_page.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class JournalEntriesScreen extends StatefulWidget {
  final AppUser user;
  const JournalEntriesScreen({super.key, required this.user});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  final _journalService = JournalService();

  @override
  Widget build(BuildContext context) {
    return VoucherListPage<JournalEntryModel>(
      title: 'Journal Entries',
      subtitle: 'Record and track manual accounting entries',
      stream: _journalService.getJournalEntries(widget.user.companyId!),
      onAddNew: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateJournalEntryScreen(user: widget.user),
          ),
        );
      },
      columns: const ['Date', 'Reference', 'Description', 'Total Amount', 'Status', 'Actions'],
      emptyTitle: 'No journal entries found',
      emptyMessage: 'Start by creating your first manual journal entry.',
      rowBuilder: (entry, index) {
        final totalDebit = entry.lines.fold(0.0, (sum, line) => sum + line.debit);
        
        return DataRow(
          cells: [
            DataCell(Text(AppFormatters.date(entry.date))),
            DataCell(Text(entry.reference, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(entry.description)),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppFormatters.currency(totalDebit),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(ERPStatusBadge.fromStatus(entry.status.name)),
            DataCell(
              VoucherActionMenu(
                onView: () {
                   // Show detail expansion or separate screen
                },
                onEdit: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit screen not wired yet.')),
                  );
                },
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (innerContext) => ERPConfirmDeleteDialog(
                      title: 'Delete Journal Entry',
                      message: 'Are you sure you want to delete entry ${entry.reference}?',
                      onConfirm: () async {
                        try {
                          await _journalService.deleteJournalEntry(widget.user.companyId!, entry.id);
                        } catch (e) {
                          if (context.mounted) showErpError(context: context, error: e);
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
    );
  }
}
