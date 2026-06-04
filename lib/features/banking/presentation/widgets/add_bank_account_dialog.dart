import 'package:flutter/material.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/services/bank_account_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

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
  final _companyService = CompanyService();

  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _ibanController = TextEditingController();
  final _openingBalanceController = TextEditingController();

  BankAccountType _type = BankAccountType.bank;
  String? _selectedChartAccountId;
  CompanyModel? _company;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  void _loadCompany() {
    _companyService.getCompany(widget.companyId).listen((company) {
      if (mounted) setState(() => _company = company);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErpGlassModal(
      title: 'Add Bank/Cash Account',
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      saveLabel: 'Add Account',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              style: ErpFormStyle.inputStyle(context),
              decoration: ErpFormStyle.inputDecoration(
                context,
                'Account Display Name',
                icon: Icons.account_balance_wallet_outlined,
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<BankAccountType>(
              initialValue: _type,
              dropdownColor: Theme.of(context).colorScheme.surface,
              style: ErpFormStyle.inputStyle(context),
              decoration: ErpFormStyle.inputDecoration(
                context,
                'Account Type',
                icon: Icons.category_outlined,
              ),
              items: BankAccountType.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e.name.toUpperCase(),
                        style: ErpFormStyle.inputStyle(context),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 20),

            StreamBuilder<List<AccountModel>>(
              stream: _chartService.getAccounts(widget.companyId),
              builder: (context, snapshot) {
                final assetAccounts = (snapshot.data ?? [])
                    .where((a) => a.accountType == AccountType.asset)
                    .toList();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedChartAccountId,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(
                    context,
                    'Linked Chart of Account',
                    icon: Icons.link,
                  ),
                  items: assetAccounts
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            '${a.accountCode} - ${a.accountName}',
                            style: ErpFormStyle.inputStyle(context),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedChartAccountId = v),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 20),

            if (_type != BankAccountType.cash) ...[
              TextFormField(
                controller: _bankNameController,
                style: ErpFormStyle.inputStyle(context),
                decoration: ErpFormStyle.inputDecoration(
                  context,
                  'Bank Name',
                  icon: Icons.account_balance_outlined,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numberController,
                      style: ErpFormStyle.inputStyle(context),
                      decoration: ErpFormStyle.inputDecoration(
                        context,
                        'Account Number',
                        icon: Icons.numbers_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _ibanController,
                      style: ErpFormStyle.inputStyle(context),
                      decoration: ErpFormStyle.inputDecoration(
                        context,
                        'IBAN',
                        icon: Icons.public_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            TextFormField(
              controller: _openingBalanceController,
              style: ErpFormStyle.inputStyle(context),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: ErpFormStyle.inputDecoration(
                context,
                'Opening Balance',
                icon: Icons.money_outlined,
                prefixText: '${_company?.baseCurrency ?? 'AED'} ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
          ],
        ),
      ),
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
        currency: _company?.baseCurrency ?? 'AED',
        linkedChartAccountId: _selectedChartAccountId!,
        openingBalance: double.parse(_openingBalanceController.text),
        currentBalance: double.parse(_openingBalanceController.text),
        createdAt: DateTime.now(),
      );

      await _accountService.addBankAccount(account);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
