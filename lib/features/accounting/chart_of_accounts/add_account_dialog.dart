import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAccountDialog extends StatefulWidget {
  final String companyId;
  final AccountModel? account;
  final bool isReadOnly;

  const AddAccountDialog({
    super.key,
    required this.companyId,
    this.account,
    this.isReadOnly = false,
  });

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  late AccountType _selectedType;
  late AccountCategory _selectedCategory;
  AccountModel? _parentAccount;
  late bool _isGroup;
  late bool _allowPosting;
  late BalanceType _balanceType;
  late DateTime _openingDate;
  bool _isLoading = false;

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

    _selectedType = acc?.accountType ?? AccountType.asset;
    _selectedCategory = acc?.accountCategory ?? AccountCategory.currentAsset;
    _isGroup = acc?.isGroup ?? false;
    _allowPosting = acc?.allowPosting ?? true;
    _balanceType = acc?.openingBalanceType ?? BalanceType.debit;
    _openingDate = acc?.openingBalanceDate ?? DateTime.now();

    _loadAccounts();
  }

  void _loadAccounts() {
    _accountService.getAccounts(widget.companyId).listen((accounts) {
      if (mounted) {
        setState(() {
          _allAccounts = accounts;
          if (widget.account?.parentAccountId != null) {
            _parentAccount = accounts.firstWhere(
              (a) => a.id == widget.account!.parentAccountId,
              orElse: () => null as dynamic,
            );
          }
        });
      }
    });
  }

  void _updateDefaultBalanceType(AccountType type) {
    if (widget.account != null) return; // Don't auto-update if editing
    setState(() {
      _balanceType = _accountService.getDefaultBalance(type);
    });
  }

  Future<void> _save() async {
    if (widget.isReadOnly) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final parentAccount = _isGroup ? null : _parentAccount;
      final account = AccountModel(
        id: widget.account?.id ?? '', // Firestore will generate if empty
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
    final title = widget.isReadOnly
        ? 'Account Details'
        : (widget.account == null ? 'Add New Account' : 'Edit Account');

    return ErpGlassModal(
      title: title,
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: widget.isReadOnly ? () => Navigator.pop(context) : _save,
      saveLabel: widget.isReadOnly ? 'Close' : 'Save Account',
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
                    readOnly: widget.isReadOnly,
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
                    readOnly: widget.isReadOnly,
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
            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              style: ErpFormStyle.inputStyle(context),
              decoration: ErpFormStyle.inputDecoration(
                context,
                'Account Type',
                icon: Icons.category_outlined,
              ),
              items: AccountType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.label,
                    style: ErpFormStyle.inputStyle(context),
                  ),
                );
              }).toList(),
              onChanged: widget.isReadOnly
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                          _updateDefaultBalanceType(val);
                        });
                      }
                    },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: Text(
                      'Is Group?',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                    subtitle: Text(
                      'Cannot post to groups',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    value: _isGroup,
                    activeThumbColor: Colors.blueAccent,
                    onChanged: widget.isReadOnly
                        ? null
                        : (val) => setState(() {
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
                const SizedBox(width: 24),
                Expanded(
                  child: SwitchListTile(
                    title: Text(
                      'Allow Posting?',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                    value: _allowPosting,
                    activeThumbColor: Colors.blueAccent,
                    onChanged: widget.isReadOnly || _isGroup
                        ? null
                        : (val) => setState(() => _allowPosting = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (_isGroup) ...[
              const SizedBox(height: 20),
              DropdownButtonFormField<AccountCategory>(
                initialValue: _selectedCategory,
                style: ErpFormStyle.inputStyle(context),
                decoration: ErpFormStyle.inputDecoration(
                  context,
                  'Account Category',
                  icon: Icons.account_tree_outlined,
                ),
                items: AccountCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat.label,
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  );
                }).toList(),
                onChanged: widget.isReadOnly
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
              ),
            ] else ...[
              const SizedBox(height: 20),
              DropdownButtonFormField<AccountModel?>(
                initialValue: _parentAccount,
                style: ErpFormStyle.inputStyle(context),
                decoration: ErpFormStyle.inputDecoration(
                  context,
                  'Parent Account',
                  icon: Icons.folder_outlined,
                ),
                items: [
                  DropdownMenuItem<AccountModel?>(
                    value: null,
                    child: Text(
                      'None (Top Level)',
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  ),
                  ..._allAccounts
                      .where((a) => a.isGroup && a.id != widget.account?.id)
                      .map((acc) {
                        return DropdownMenuItem(
                          value: acc,
                          child: Text(
                            '${acc.accountCode} - ${acc.accountName}',
                            style: ErpFormStyle.inputStyle(context),
                          ),
                        );
                      }),
                ],
                onChanged: widget.isReadOnly
                    ? null
                    : (val) => setState(() => _parentAccount = val),
              ),
            ],
            const SizedBox(height: 24),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 20),
            Text(
              'Opening Balance',
              style: ErpFormStyle.sectionHeaderStyle(context),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _balanceController,
                    enabled: !widget.isReadOnly && !_isGroup,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Amount',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                    initialValue: _balanceType,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Type'),
                    items: BalanceType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.label,
                          style: ErpFormStyle.inputStyle(context),
                        ),
                      );
                    }).toList(),
                    onChanged: widget.isReadOnly || _isGroup
                        ? null
                        : (val) => setState(() => _balanceType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: widget.isReadOnly || _isGroup
                  ? null
                  : () async {
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
            if (widget.account != null) ...[
              const SizedBox(height: 24),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current GL Balance',
                    style: ErpFormStyle.labelStyle(context),
                  ),
                  Text(
                    '${widget.account!.openingBalanceType.shortLabel} ${NumberFormat('#,##0.00').format(widget.account!.currentBalance)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
