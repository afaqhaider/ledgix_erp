import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/inventory_service.dart';
import '../../../accounting/chart_of_accounts/account_model.dart';
import '../../../accounting/chart_of_accounts/account_service.dart';
import '../../../../widgets/searchable_selector.dart';

import 'package:ledgixerp/features/accounting/chart_of_accounts/add_account_dialog.dart';

class AddProductDialog extends StatefulWidget {
  final String companyId;
  const AddProductDialog({super.key, required this.companyId});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _accountService = AccountService();

  String _sku = '';
  String _name = '';
  String? _description;
  ProductType _type = ProductType.storable;
  double _salePrice = 0.0;
  double _costPrice = 0.0;
  AccountModel? _incomeAccount;
  AccountModel? _expenseAccount;
  AccountModel? _assetAccount;

  List<AccountModel> _allAccounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    _accountService.getAccounts(widget.companyId).listen((accounts) {
      if (mounted) {
        setState(() => _allAccounts = accounts);
      }
    });
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(companyId: widget.companyId),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final product = ProductModel(
        id: '',
        companyId: widget.companyId,
        sku: _sku,
        name: _name,
        description: _description,
        type: _type,
        salePrice: _salePrice,
        costPrice: _costPrice,
        incomeAccountId: _incomeAccount?.id,
        expenseAccountId: _expenseAccount?.id,
        assetAccountId: _assetAccount?.id,
        createdAt: DateTime.now(),
      );

      await _inventoryService.addProduct(product);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product / Service'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'SKU',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onSaved: (v) => _sku = v ?? '',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        onSaved: (v) => _name = v ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProductType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Product Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ProductType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
                  }).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Sale Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (v) => _salePrice = double.tryParse(v ?? '0') ?? 0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Cost Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (v) => _costPrice = double.tryParse(v ?? '0') ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const Text('Accounting Defaults', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SearchableSelector<AccountModel>(
                  labelText: 'Income Account',
                  items: _allAccounts.where((a) => 
                    a.accountType == AccountType.income || 
                    a.accountType == AccountType.otherIncome
                  ).toList(),
                  itemLabelBuilder: (a) => '${a.accountCode} - ${a.accountName}',
                  onSelected: (val) => setState(() => _incomeAccount = val),
                  addLabel: 'Add Account',
                  onAdd: _showAddAccountDialog,
                  initialValue: _incomeAccount,
                ),
                const SizedBox(height: 16),
                SearchableSelector<AccountModel>(
                  labelText: 'Expense / COGS Account',
                  items: _allAccounts.where((a) => 
                    a.accountType == AccountType.expense || 
                    a.accountType == AccountType.costOfSales ||
                    a.accountType == AccountType.otherExpense
                  ).toList(),
                  itemLabelBuilder: (a) => '${a.accountCode} - ${a.accountName}',
                  onSelected: (val) => setState(() => _expenseAccount = val),
                  addLabel: 'Add Account',
                  onAdd: _showAddAccountDialog,
                  initialValue: _expenseAccount,
                ),
                if (_type == ProductType.storable) ...[
                  const SizedBox(height: 16),
                  SearchableSelector<AccountModel>(
                    labelText: 'Inventory Asset Account',
                    items: _allAccounts.where((a) => a.accountType == AccountType.asset).toList(),
                    itemLabelBuilder: (a) => '${a.accountCode} - ${a.accountName}',
                    onSelected: (val) => setState(() => _assetAccount = val),
                    addLabel: 'Add Account',
                    onAdd: _showAddAccountDialog,
                    initialValue: _assetAccount,
                  ),
                ],
              ],
            ),
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
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Product'),
        ),
      ],
    );
  }
}
