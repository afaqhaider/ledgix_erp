import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountPane extends StatefulWidget {
  final String companyId;
  final AccountModel? account;
  final bool isReadOnly;
  final Function(AccountModel)? onSuccess;
  final AccountType? initialAccountType;

  const AccountPane({
    super.key,
    required this.companyId,
    this.account,
    this.isReadOnly = false,
    this.onSuccess,
    this.initialAccountType,
  });

  @override
  State<AccountPane> createState() => _AccountPaneState();
}

class _AccountPaneState extends State<AccountPane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _balanceController;

  late AccountType _selectedType;
  late AccountCategory _selectedCategory;
  AccountModel? _parentAccount;
  late bool _isGroup;
  late bool _allowPosting;
  late BalanceType _balanceType;
  late DateTime _openingDate;
  bool _isLoading = false;
  bool _isInitializing = true;

  final _accountService = AccountService();
  List<AccountModel> _allAccounts = [];

  @override
  void initState() {
    super.initState();
    final acc = widget.account;
    _codeController = TextEditingController(text: acc?.accountCode);
    _nameController = TextEditingController(text: acc?.accountName);
    _balanceController = TextEditingController(
      text: acc?.openingBalance.toStringAsFixed(2) ?? '0.00',
    );

    _selectedType = acc?.accountType ?? widget.initialAccountType ?? AccountType.asset;
    _selectedCategory = acc?.accountCategory ?? AccountCategory.currentAsset;
    _isGroup = acc?.isGroup ?? false;
    _allowPosting = acc?.allowPosting ?? true;
    _balanceType = acc?.openingBalanceType ?? _accountService.getDefaultBalance(_selectedType);
    _openingDate = acc?.openingBalanceDate ?? DateTime.now();

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _accountService.getAccounts(widget.companyId).first;
      if (mounted) {
        setState(() {
          _allAccounts = accounts;
          if (widget.account?.parentAccountId != null) {
            _parentAccount = accounts.cast<AccountModel?>().firstWhere(
              (a) => a?.id == widget.account!.parentAccountId,
              orElse: () => null,
            );
          }
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
        showErpError(context: context, error: e);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.isReadOnly) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final parentAccount = _isGroup ? null : _parentAccount;
      final account = AccountModel(
        id: widget.account?.id ?? '',
        companyId: widget.companyId,
        accountCode: _codeController.text.trim(),
        accountName: _nameController.text.trim(),
        accountType: _selectedType,
        accountCategory: _selectedCategory,
        parentAccountId: parentAccount?.id,
        level: (parentAccount?.level ?? -1) + 1,
        isGroup: _isGroup,
        allowPosting: _isGroup ? false : _allowPosting,
        normalBalance: _balanceType,
        isSystemAccount: widget.account?.isSystemAccount ?? false,
        isActive: widget.account?.isActive ?? true,
        openingBalance: double.tryParse(_balanceController.text) ?? 0.0,
        openingBalanceType: _balanceType,
        openingBalanceDate: _openingDate,
        currentBalance: widget.account?.currentBalance ?? 0.0,
        createdAt: widget.account?.createdAt ?? DateTime.now(),
      );

      if (widget.account == null) {
        await _accountService.addAccount(account);
      } else {
        await _accountService.updateAccount(account);
      }
      
      if (widget.onSuccess != null) widget.onSuccess!(account);

      if (mounted) {
        Navigator.pop(context);
        showErpSuccess(
          context: context,
          title: 'Success',
          message: 'Account ${widget.account == null ? 'added' : 'updated'} successfully.',
        );
      }
    } catch (e) {
      if (mounted) showErpError(context: context, error: e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ));
    }

    final theme = Theme.of(context);
    final title = widget.isReadOnly
        ? 'Account Details'
        : (widget.account == null ? 'Add New Account' : 'Edit Account');

    return ErpSidePane(
      title: title,
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: widget.isReadOnly ? () => Navigator.pop(context) : _save,
      saveLabel: widget.isReadOnly ? 'Close' : 'Save Account',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeController,
                    readOnly: widget.isReadOnly,
                    decoration: ErpFormStyle.inputDecoration(context, 'Account Code *', icon: Icons.tag),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    readOnly: widget.isReadOnly,
                    decoration: ErpFormStyle.inputDecoration(context, 'Account Name *', icon: Icons.label_outline),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountType>(
              value: _selectedType,
              decoration: ErpFormStyle.inputDecoration(context, 'Account Type', icon: Icons.category_outlined),
              items: AccountType.values.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.label, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: widget.isReadOnly ? null : (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                    _balanceType = _accountService.getDefaultBalance(val);
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Text('Configuration', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Is Group?', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Cannot post to groups', style: TextStyle(fontSize: 11)),
                    value: _isGroup,
                    activeThumbColor: Colors.blueAccent,
                    onChanged: widget.isReadOnly ? null : (val) => setState(() {
                      _isGroup = val;
                      if (_isGroup) {
                        _allowPosting = false;
                        _balanceController.text = '0.00';
                        _parentAccount = null;
                      }
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Allow Posting?', style: TextStyle(fontSize: 13)),
                    value: _allowPosting,
                    activeThumbColor: Colors.blueAccent,
                    onChanged: widget.isReadOnly || _isGroup ? null : (val) => setState(() => _allowPosting = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isGroup)
              DropdownButtonFormField<AccountCategory>(
                value: _selectedCategory,
                decoration: ErpFormStyle.inputDecoration(context, 'Account Category', icon: Icons.account_tree_outlined),
                items: AccountCategory.values.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.label, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: widget.isReadOnly ? null : (val) => setState(() => _selectedCategory = val!),
              )
            else
              SearchableSelector<AccountModel>(
                labelText: 'Parent Account',
                items: _allAccounts.where((a) => a.isGroup && a.id != widget.account?.id).toList(),
                itemLabelBuilder: (a) => '${a.accountCode} - ${a.accountName}',
                onSelected: (val) => setState(() => _parentAccount = val),
                initialValue: _parentAccount,
              ),
            
            const SizedBox(height: 32),
            Text('Opening Balance', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _balanceController,
                    enabled: !widget.isReadOnly && !_isGroup,
                    decoration: ErpFormStyle.inputDecoration(context, 'Amount', icon: Icons.account_balance_wallet_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<BalanceType>(
                    value: _balanceType,
                    decoration: ErpFormStyle.inputDecoration(context, 'Type'),
                    items: BalanceType.values.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type.label, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: widget.isReadOnly || _isGroup ? null : (val) => setState(() => _balanceType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: widget.isReadOnly || _isGroup ? null : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _openingDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _openingDate = picked);
              },
              child: InputDecorator(
                decoration: ErpFormStyle.inputDecoration(context, 'Opening Balance Date', icon: Icons.calendar_today_outlined),
                child: Text(DateFormat('yyyy-MM-dd').format(_openingDate), style: const TextStyle(fontSize: 13)),
              ),
            ),
            if (widget.account != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Ledger Balance', style: ErpFormStyle.labelStyle(context)),
                  Text(
                    '${widget.account!.openingBalanceType.shortLabel} ${NumberFormat('#,##0.00').format(widget.account!.currentBalance)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
