import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_line_model.dart';
import 'package:ledgixerp/features/accounting/journal/services/journal_service.dart';

class CreateJournalEntryScreen extends StatefulWidget {
  final AppUser user;
  const CreateJournalEntryScreen({super.key, required this.user});

  @override
  State<CreateJournalEntryScreen> createState() => _CreateJournalEntryScreenState();
}

class _CreateJournalEntryScreenState extends State<CreateJournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
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
    _loadAccounts();
    // Start with 2 empty lines
    _addLine();
    _addLine();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _accountService.getAccounts(widget.user.companyId!).first;
    setState(() => _accounts = accounts);
  }

  void _addLine() {
    setState(() {
      _lines.add(JournalLineModel(
        accountId: '',
        accountName: '',
        accountCode: '',
        debit: 0,
        credit: 0,
      ));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    double totalDebit = _lines.fold(0, (sum, item) => sum + item.debit);
    double totalCredit = _lines.fold(0, (sum, item) => sum + item.credit);

    if ((totalDebit - totalCredit).abs() > 0.001) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry is not balanced!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entry = JournalEntryModel(
        id: '',
        companyId: widget.user.companyId!,
        date: _selectedDate,
        reference: _refController.text.trim(),
        description: _descController.text.trim(),
        lines: _lines.where((l) => l.accountId.isNotEmpty).toList(),
        createdBy: widget.user.uid,
        createdAt: DateTime.now(),
      );

      await _journalService.addJournalEntry(entry);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Journal Entry'),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Post Entry'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _refController,
                          decoration: const InputDecoration(labelText: 'Reference', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
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
                            if (date != null) setState(() => _selectedDate = date);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                            child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
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
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              const Text('Journal Lines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Padding(padding: EdgeInsets.all(8), child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('')),
          ],
        ),
        ..._lines.asMap().entries.map((entry) {
          int index = entry.key;
          JournalLineModel line = entry.value;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: DropdownButtonFormField<String>(
                  initialValue: line.accountId.isEmpty ? null : line.accountId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.accountCode} - ${a.accountName}'))).toList(),
                  onChanged: (val) {
                    final acc = _accounts.firstWhere((a) => a.id == val);
                    setState(() {
                      _lines[index] = JournalLineModel(
                        accountId: acc.id,
                        accountName: acc.accountName,
                        accountCode: acc.accountCode,
                        debit: line.debit,
                        credit: line.credit,
                      );
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: line.debit == 0 ? '' : line.debit.toString(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      _lines[index] = JournalLineModel(
                        accountId: line.accountId,
                        accountName: line.accountName,
                        accountCode: line.accountCode,
                        debit: double.tryParse(val) ?? 0,
                        credit: 0, // Reset credit if debit is set
                      );
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: line.credit == 0 ? '' : line.credit.toString(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      _lines[index] = JournalLineModel(
                        accountId: line.accountId,
                        accountName: line.accountName,
                        accountCode: line.accountCode,
                        debit: 0, // Reset debit if credit is set
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
