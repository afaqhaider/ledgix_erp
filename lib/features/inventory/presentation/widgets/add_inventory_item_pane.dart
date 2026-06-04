import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:uuid/uuid.dart';

class AddInventoryItemPane extends StatefulWidget {
  final AppUser user;
  final InventoryItemModel? item;

  const AddInventoryItemPane({super.key, required this.user, this.item});

  @override
  State<AddInventoryItemPane> createState() => _AddInventoryItemPaneState();
}

class _AddInventoryItemPaneState extends State<AddInventoryItemPane> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _accountService = AccountService();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _salesPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _uomController;
  late TextEditingController _categoryController;

  InventoryItemType _itemType = InventoryItemType.stock;
  String? _inventoryAccountId;
  String? _incomeAccountId;
  String? _expenseAccountId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.item?.itemCode);
    _nameController = TextEditingController(text: widget.item?.itemName);
    _salesPriceController = TextEditingController(
      text: widget.item?.salesPrice.toString() ?? '0.00',
    );
    _purchasePriceController = TextEditingController(
      text: widget.item?.purchasePrice.toString() ?? '0.00',
    );
    _uomController = TextEditingController(
      text: widget.item?.defaultUomId ?? 'Units',
    );
    _categoryController = TextEditingController(text: widget.item?.itemCategoryId);
    _itemType = widget.item?.itemType ?? InventoryItemType.stock;
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
      itemType: _itemType,
      itemCategoryId: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      defaultUomId: _uomController.text.trim(),
      salesPrice: double.tryParse(_salesPriceController.text) ?? 0,
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
      inventoryAccountId: _inventoryAccountId,
      incomeAccountId: _incomeAccountId,
      expenseAccountId: _expenseAccountId,
      isActive: _isActive,
      createdAt: widget.item?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.item == null) {
        await _inventoryService.addItem(item);
      } else {
        await _inventoryService.updateItem(item);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Code*',
                    hintText: 'SKU-001',
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<InventoryItemType>(
                  value: _itemType,
                  decoration: const InputDecoration(labelText: 'Type*'),
                  items: InventoryItemType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _itemType = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Item Name*'),
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _uomController,
                  decoration: const InputDecoration(
                    labelText: 'Unit of Measure*',
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Financial Mapping',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _salesPriceController,
                  decoration: const InputDecoration(labelText: 'Sales Price'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
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
          const SizedBox(height: 16),
          StreamBuilder<List<AccountModel>>(
            stream: _accountService.getAccounts(widget.user.companyId!),
            builder: (context, snapshot) {
              final accounts = snapshot.data ?? [];
              return Column(
                children: [
                  if (_itemType == InventoryItemType.stock)
                    DropdownButtonFormField<String>(
                      value: _inventoryAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Inventory Account',
                      ),
                      items: accounts
                          .where((a) => a.accountType == AccountType.asset)
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.accountCode} - ${a.accountName}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _inventoryAccountId = v),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _incomeAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Income Account',
                    ),
                    items: accounts
                        .where((a) => a.accountType == AccountType.income)
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.accountCode} - ${a.accountName}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _incomeAccountId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _expenseAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Expense/COGS Account',
                    ),
                    items: accounts
                        .where(
                          (a) =>
                              a.accountType == AccountType.expense ||
                              a.accountType == AccountType.costOfSales,
                        )
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.accountCode} - ${a.accountName}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _expenseAccountId = v),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Is Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(widget.item == null ? 'Create Item' : 'Update Item'),
            ),
          ),
        ],
      ),
    );
  }
}
