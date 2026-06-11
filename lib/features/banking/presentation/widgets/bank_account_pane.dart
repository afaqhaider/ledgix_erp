import 'package:flutter/material.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/services/bank_account_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class BankAccountPane extends StatefulWidget {
  final String companyId;
  final BankAccountModel? account; // If provided, we are editing

  const BankAccountPane({
    super.key,
    required this.companyId,
    this.account,
  });

  @override
  State<BankAccountPane> createState() => _BankAccountPaneState();
}

class _BankAccountPaneState extends State<BankAccountPane> {
  final _formKey = GlobalKey<FormState>();
  final _accountService = BankAccountService();
  final _chartService = AccountService();
  final _companyService = CompanyService();

  late TextEditingController _nameController;
  late TextEditingController _bankNameController;
  late TextEditingController _numberController;
  late TextEditingController _ibanController;
  late TextEditingController _openingBalanceController;

  late BankAccountType _type;
  String? _selectedChartAccountId;
  CompanyModel? _company;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.accountName);
    _bankNameController = TextEditingController(text: widget.account?.bankName);
    _numberController = TextEditingController(text: widget.account?.accountNumber);
    _ibanController = TextEditingController(text: widget.account?.iban);
    _openingBalanceController = TextEditingController(
      text: widget.account?.openingBalance.toString() ?? '0.0',
    );
    _type = widget.account?.accountType ?? BankAccountType.bank;
    _selectedChartAccountId = widget.account?.linkedChartAccountId;
    _loadCompany();
  }

  void _loadCompany() {
    _companyService.getCompany(widget.companyId).first.then((company) {
      if (mounted) setState(() => _company = company);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _numberController.dispose();
    _ibanController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErpSidePane(
      title: widget.account == null ? 'Add Bank/Cash Account' : 'Edit Account',
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      saveLabel: widget.account == null ? 'Add Account' : 'Update Account',
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
            const SizedBox(height: 16),

            DropdownButtonFormField<BankAccountType>(
              value: _type,
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
            const SizedBox(height: 16),

            StreamBuilder<List<AccountModel>>(
              stream: _chartService.getAccounts(widget.companyId),
              builder: (context, snapshot) {
                final assetAccounts = (snapshot.data ?? [])
                    .where((a) => a.accountType == AccountType.asset && !a.isGroup)
                    .toList();
                
                return DropdownButtonFormField<String>(
                  value: _selectedChartAccountId,
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
                style: ErpFormStyle.inputStyle(context),
                decoration: ErpFormStyle.inputDecoration(
                  context,
                  'Bank Name',
                  icon: Icons.account_balance_outlined,
                ),
              ),
              const SizedBox(height: 16),
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
                  const SizedBox(width: 12),
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
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _openingBalanceController,
              style: ErpFormStyle.inputStyle(context),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: widget.account == null, // Only allowed on creation
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
      if (widget.account == null) {
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
      } else {
        final updated = widget.account!.copyWith(
          accountName: _nameController.text.trim(),
          accountType: _type,
          bankName: _bankNameController.text.trim(),
          accountNumber: _numberController.text.trim(),
          iban: _ibanController.text.trim(),
          linkedChartAccountId: _selectedChartAccountId!,
        );
        await _accountService.updateBankAccount(updated);
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

extension on BankAccountModel {
  BankAccountModel copyWith({
    String? accountName,
    BankAccountType? accountType,
    String? bankName,
    String? accountNumber,
    String? iban,
    String? linkedChartAccountId,
  }) {
    return BankAccountModel(
      id: id,
      companyId: companyId,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      currency: currency,
      linkedChartAccountId: linkedChartAccountId ?? this.linkedChartAccountId,
      openingBalance: openingBalance,
      currentBalance: currentBalance,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
