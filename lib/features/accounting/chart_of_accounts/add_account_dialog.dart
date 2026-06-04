import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class AddAccountDialog extends StatefulWidget {
  final String companyId;

  const AddAccountDialog({super.key, required this.companyId});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');

  AccountType _selectedType = AccountType.asset;
  AccountCategory _selectedCategory = AccountCategory.currentAsset;
  AccountModel? _parentAccount;
  bool _isGroup = false;
  bool _allowPosting = true;
  BalanceType _balanceType = BalanceType.debit;
  DateTime _openingDate = DateTime.now();
  bool _isLoading = false;

  final _accountService = AccountService();
  List<AccountModel> _allAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountService.getAccounts(widget.companyId).listen((accounts) {
      if (mounted) {
        setState(() {
          _allAccounts = accounts;
        });
      }
    });
  }

  void _updateDefaultBalanceType(AccountType type) {
    setState(() {
      _balanceType = _accountService.getDefaultBalance(type);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final account = AccountModel(
        id: '', // Firestore will generate
        companyId: widget.companyId,
        accountCode: _codeController.text.trim(),
        accountName: _nameController.text.trim(),
        accountType: _selectedType,
        accountCategory: _selectedCategory,
        parentAccountId: _parentAccount?.id,
        level: (_parentAccount?.level ?? -1) + 1,
        isGroup: _isGroup,
        allowPosting: _isGroup ? false : _allowPosting,
        normalBalance: _balanceType,
        isSystemAccount: false,
        openingBalance: double.tryParse(_balanceController.text) ?? 0.0,
        openingBalanceType: _balanceType,
        openingBalanceDate: _openingDate,
        createdAt: DateTime.now(),
      );

      await _accountService.addAccount(account);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErpGlassModal(
      title: 'Add New Account',
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      saveLabel: 'Save Account',
      width: 600,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Account Code',
                      icon: Icons.tag,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Account Name',
                      icon: Icons.label_outline,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<AccountType>(
                    value: _selectedType,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Account Type',
                      icon: Icons.category_outlined,
                    ),
                    items: AccountType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label, style: ErpFormStyle.inputStyle(context)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                          _updateDefaultBalanceType(val);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<AccountCategory>(
                    value: _selectedCategory,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Category',
                      icon: Icons.account_tree_outlined,
                    ),
                    items: AccountCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.label, style: ErpFormStyle.inputStyle(context)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<AccountModel?>(
              value: _parentAccount,
              style: ErpFormStyle.inputStyle(context),
              decoration: ErpFormStyle.inputDecoration(
                context,
                'Parent Account (Optional)',
                icon: Icons.folder_outlined,
              ),
              items: [
                DropdownMenuItem<AccountModel?>(
                  value: null,
                  child: Text('None (Top Level)', style: ErpFormStyle.inputStyle(context)),
                ),
                ..._allAccounts.where((a) => a.isGroup).map((acc) {
                  return DropdownMenuItem(
                    value: acc,
                    child: Text('${acc.accountCode} - ${acc.accountName}', style: ErpFormStyle.inputStyle(context)),
                  );
                }),
              ],
              onChanged: (val) => setState(() => _parentAccount = val),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: Text('Is Group?', style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
                    subtitle: Text('Cannot post to groups', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    value: _isGroup,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) => setState(() {
                      _isGroup = val;
                      if (_isGroup) {
                        _allowPosting = false;
                        _balanceController.text = '0.00';
                      }
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SwitchListTile(
                    title: Text('Allow Posting?', style: theme.textTheme.bodySmall?.copyWith(fontSize: 13)),
                    value: _allowPosting,
                    activeColor: Colors.blueAccent,
                    onChanged: _isGroup
                        ? null
                        : (val) => setState(() => _allowPosting = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 20),
            Text('Opening Balance', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _balanceController,
                    enabled: !_isGroup,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Amount',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (_isGroup && (double.tryParse(v ?? '0') ?? 0) != 0) {
                        return 'Must be 0 for groups';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<BalanceType>(
                    value: _balanceType,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Type'),
                    items: BalanceType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label, style: ErpFormStyle.inputStyle(context)),
                      );
                    }).toList(),
                    onChanged: _isGroup ? null : (val) => setState(() => _balanceType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _isGroup ? null : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _openingDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _openingDate = picked);
                }
              },
              child: InputDecorator(
                decoration: ErpFormStyle.inputDecoration(
                  context,
                  'Opening Balance Date',
                  icon: Icons.calendar_today_outlined,
                ),
                child: Text(
                  DateFormat('yyyy-MM-dd').format(_openingDate),
                  style: ErpFormStyle.inputStyle(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
