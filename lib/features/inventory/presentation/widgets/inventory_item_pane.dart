import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:uuid/uuid.dart';

class InventoryItemPane extends StatefulWidget {
  final AppUser user;
  final InventoryItemModel? item;

  const InventoryItemPane({super.key, required this.user, this.item});

  @override
  State<InventoryItemPane> createState() => _InventoryItemPaneState();
}

class _InventoryItemPaneState extends State<InventoryItemPane> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _accountService = AccountService();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _salesPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _reorderController;
  late TextEditingController _minStockController;
  late TextEditingController _maxStockController;

  InventoryItemType _itemType = InventoryItemType.stock;
  String? _categoryId;
  String? _uomId;
  String? _inventoryAccountId;
  String? _incomeAccountId;
  String? _expenseAccountId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.item?.itemCode);
    _nameController = TextEditingController(text: widget.item?.itemName);
    _descController = TextEditingController(text: widget.item?.itemDescription);
    _salesPriceController = TextEditingController(
      text: widget.item?.salesPrice.toString() ?? '0.00',
    );
    _purchasePriceController = TextEditingController(
      text: widget.item?.purchasePrice.toString() ?? '0.00',
    );
    _reorderController = TextEditingController(
      text: widget.item?.reorderLevel.toString() ?? '0.00',
    );
    _minStockController = TextEditingController(
      text: widget.item?.minimumStock.toString() ?? '0.00',
    );
    _maxStockController = TextEditingController(
      text: widget.item?.maximumStock.toString() ?? '0.00',
    );

    _itemType = widget.item?.itemType ?? InventoryItemType.stock;
    _categoryId = widget.item?.itemCategoryId;
    _uomId = widget.item?.defaultUomId;
    _inventoryAccountId = widget.item?.inventoryAccountId;
    _incomeAccountId = widget.item?.incomeAccountId;
    _expenseAccountId = widget.item?.expenseAccountId;
    _isActive = widget.item?.isActive ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final item = InventoryItemModel(
      id: widget.item?.id ?? const Uuid().v4(),
      companyId: widget.user.companyId!,
      itemCode: _codeController.text.trim(),
      itemName: _nameController.text.trim(),
      itemDescription: _descController.text.trim(),
      itemCategoryId: _categoryId,
      itemType: _itemType,
      defaultUomId: _uomId ?? '',
      salesPrice: double.tryParse(_salesPriceController.text) ?? 0,
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
      inventoryAccountId: _inventoryAccountId,
      incomeAccountId: _incomeAccountId,
      expenseAccountId: _expenseAccountId,
      reorderLevel: double.tryParse(_reorderController.text) ?? 0,
      minimumStock: double.tryParse(_minStockController.text) ?? 0,
      maximumStock: double.tryParse(_maxStockController.text) ?? 0,
      isActive: _isActive,
      createdAt: widget.item?.createdAt ?? DateTime.now(),
    );

    try {
      await _inventoryService.addItem(item);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error adding item')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Item Code*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InventoryItemType>(
              initialValue: _itemType,
              items: InventoryItemType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _itemType = v!),
              decoration: const InputDecoration(labelText: 'Item Type'),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<InventoryCategoryModel>>(
              stream: _inventoryService.getCategories(widget.user.companyId!),
              builder: (context, snapshot) {
                final cats = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  items: cats
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  decoration: const InputDecoration(labelText: 'Category'),
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<UomModel>>(
              stream: _inventoryService.getUoms(widget.user.companyId!),
              builder: (context, snapshot) {
                final uoms = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _uomId,
                  items: uoms
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.uomName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _uomId = v),
                  decoration: const InputDecoration(labelText: 'Default UOM*'),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Pricing & Accounts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salesPriceController,
                    decoration: const InputDecoration(labelText: 'Sales Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceController,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Price',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<AccountModel>>(
              stream: _accountService.getAccounts(widget.user.companyId!),
              builder: (context, snapshot) {
                final accounts = snapshot.data ?? [];
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _inventoryAccountId,
                      items: accounts
                          .where((a) => a.accountType == AccountType.asset)
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.accountName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _inventoryAccountId = v),
                      decoration: const InputDecoration(
                        labelText: 'Inventory Account',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _incomeAccountId,
                      items: accounts
                          .where((a) => a.accountType == AccountType.income)
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.accountName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _incomeAccountId = v),
                      decoration: const InputDecoration(
                        labelText: 'Income Account',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _expenseAccountId,
                      items: accounts
                          .where(
                            (a) =>
                                a.accountType == AccountType.expense ||
                                a.accountType == AccountType.costOfSales,
                          )
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.accountName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _expenseAccountId = v),
                      decoration: const InputDecoration(
                        labelText: 'Expense/COGS Account',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Stock Limits',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: const InputDecoration(labelText: 'Min Stock'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _reorderController,
                    decoration: const InputDecoration(
                      labelText: 'Reorder Level',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxStockController,
                    decoration: const InputDecoration(labelText: 'Max Stock'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Is Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: _save, child: const Text('Save Item')),
          ],
        ),
      ),
    );
  }
}
