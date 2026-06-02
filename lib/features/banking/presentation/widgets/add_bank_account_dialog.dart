import 'package:flutter/material.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/services/bank_account_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';

class AddBankAccountDialog extends StatefulWidget {
  final String companyId;
  const AddBankAccountDialog({super.key, required this.companyId});

  @override
  State<AddBankAccountDialog> createState() => _AddBankAccountDialogState();
}

class _AddBankAccountDialogState extends State<AddBankAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountService = BankAccountService();
  final _chartService = AccountService();

  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _ibanController = TextEditingController();
  final _openingBalanceController = TextEditingController();

  BankAccountType _type = BankAccountType.bank;
  String? _selectedChartAccountId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Bank/Cash Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Display Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BankAccountType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: BankAccountType.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<AccountModel>>(
                stream: _chartService.getAccounts(widget.companyId),
                builder: (context, snapshot) {
                  final assetAccounts = (snapshot.data ?? [])
                      .where((a) => a.accountType == AccountType.asset)
                      .toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedChartAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Linked Chart of Account (Asset)',
                      border: OutlineInputBorder(),
                    ),
                    items: assetAccounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.accountCode} - ${a.accountName}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedChartAccountId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_type != BankAccountType.cash) ...[
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ibanController,
                  decoration: const InputDecoration(
                    labelText: 'IBAN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _openingBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Opening Balance',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: const Text('Save Account'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final account = BankAccountModel(
        id: '',
        companyId: widget.companyId,
        accountName: _nameController.text.trim(),
        accountType: _type,
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        accountNumber: _numberController.text.trim().isEmpty
            ? null
            : _numberController.text.trim(),
        iban: _ibanController.text.trim().isEmpty
            ? null
            : _ibanController.text.trim(),
        currency: 'USD',
        linkedChartAccountId: _selectedChartAccountId!,
        openingBalance: double.parse(_openingBalanceController.text),
        currentBalance: double.parse(_openingBalanceController.text),
        createdAt: DateTime.now(),
      );

      await _accountService.addBankAccount(account);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
