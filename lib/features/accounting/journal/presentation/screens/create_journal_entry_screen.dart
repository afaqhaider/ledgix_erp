import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_line_model.dart';
import 'package:ledgixerp/features/accounting/journal/services/journal_service.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/add_account_dialog.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/posting_error_modal.dart';

class CreateJournalEntryScreen extends StatefulWidget {
  final AppUser user;
  const CreateJournalEntryScreen({super.key, required this.user});

  @override
  State<CreateJournalEntryScreen> createState() =>
      _CreateJournalEntryScreenState();
}

class _CreateJournalEntryScreenState extends State<CreateJournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _journalNumber = 'Loading...';
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<JournalLineModel> _lines = [];
  bool _isLoading = false;

  final _accountService = AccountService();
  final _journalService = JournalService();
  List<AccountModel> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _addLine();
    _addLine();
    _listenToAccounts();
  }

  void _listenToAccounts() {
    _accountService.getAccounts(widget.user.companyId!).listen((accounts) {
      if (mounted) {
        setState(() {
          // Only allow posting to non-group accounts that allow posting
          _accounts = accounts
              .where((a) => !a.isGroup && a.allowPosting)
              .toList();
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    final number = await _journalService.generateNextJournalNumber(
      widget.user.companyId!,
    );
    if (mounted) {
      setState(() => _journalNumber = number);
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(
        JournalLineModel(
          accountId: '',
          accountName: '',
          accountCode: '',
          debit: 0,
          credit: 0,
        ),
      );
    });
  }

  bool get _canPost {
    const highRoles = [
      UserRole.owner,
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.accountant,
      UserRole.generalManager,
    ];
    return highRoles.contains(widget.user.role);
  }

  Future<void> _save({bool shouldPost = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (shouldPost) {
      double totalDebit = _lines.fold(0.0, (sum, item) => sum + item.debit);
      double totalCredit = _lines.fold(0.0, (sum, item) => sum + item.credit);

      if ((totalDebit - totalCredit).abs() > 0.001) {
        showErpError(
          context: context,
          title: 'Unbalanced Entry',
          message:
              'Total Debit: $totalDebit must equal Total Credit: $totalCredit',
        );
        return;
      }

      if (_lines.any(
        (l) => l.accountId.isEmpty && (l.debit > 0 || l.credit > 0),
      )) {
        showErpError(
          context: context,
          title: 'Account Required',
          message: 'All lines with amounts must have an account selected.',
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final entry = JournalEntryModel(
        id: '',
        companyId: widget.user.companyId!,
        date: _selectedDate,
        reference: 'AUTO',
        description: _descController.text.trim(),
        lines: _lines.where((l) => l.accountId.isNotEmpty).toList(),
        createdBy: widget.user.uid,
        createdAt: DateTime.now(),
        status: shouldPost && _canPost
            ? JournalStatus.posted
            : JournalStatus.draft,
        approvalStatus: shouldPost ? (_canPost ? 'approved' : 'pending') : null,
      );

      await _journalService.addJournalEntry(
        entry,
        widget.user,
        shouldPost: shouldPost,
      );
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Error saving journal: $e');
      debugPrint(stack.toString());
      if (mounted) {
        if (shouldPost) {
          PostingErrorModal.show(
            context: context,
            title: 'Posting Failed',
            message:
                'An error occurred while trying to post the journal entry.',
            error: e,
          );
        } else {
          showErpError(context: context, error: e);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(companyId: widget.user.companyId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Journal Entry'),
        actions: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => _save(shouldPost: false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
            ),
            child: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _save(shouldPost: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(_canPost ? 'Save & Post' : 'Submit for Approval'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Journal Number',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            'Next number: $_journalNumber',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              const Text(
                'Journal Lines',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLinesTable(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add),
                label: const Text('Add Line'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinesTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: IntrinsicColumnWidth(),
      },
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Debit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Credit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(padding: EdgeInsets.all(8), child: Text('')),
          ],
        ),
        ..._lines.asMap().entries.map((entry) {
          int index = entry.key;
          JournalLineModel line = entry.value;
          final currentAccount = line.accountId.isEmpty
              ? null
              : _accounts.where((a) => a.id == line.accountId).firstOrNull;

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: SearchableSelector<AccountModel>(
                  labelText: 'Select Account',
                  items: _accounts,
                  itemLabelBuilder: (a) =>
                      '${a.accountCode} - ${a.accountName}',
                  onSelected: (acc) {
                    if (acc != null) {
                      setState(() {
                        _lines[index] = JournalLineModel(
                          accountId: acc.id,
                          accountName: acc.accountName,
                          accountCode: acc.accountCode,
                          debit: line.debit,
                          credit: line.credit,
                        );
                      });
                    }
                  },
                  addLabel: 'Add Account',
                  onAdd: _showAddAccountDialog,
                  initialValue: currentAccount,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: line.debit == 0 ? '' : line.debit.toString(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      _lines[index] = JournalLineModel(
                        accountId: line.accountId,
                        accountName: line.accountName,
                        accountCode: line.accountCode,
                        debit: double.tryParse(val) ?? 0,
                        credit: 0,
                      );
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: line.credit == 0 ? '' : line.credit.toString(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      _lines[index] = JournalLineModel(
                        accountId: line.accountId,
                        accountName: line.accountName,
                        accountCode: line.accountCode,
                        debit: 0,
                        credit: double.tryParse(val) ?? 0,
                      );
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => setState(() => _lines.removeAt(index)),
              ),
            ],
          );
        }),
      ],
    );
  }
}
