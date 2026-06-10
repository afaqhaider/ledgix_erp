import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:uuid/uuid.dart';

class InventoryItemPane extends StatefulWidget {
  final AppUser user;
  final InventoryItemModel? item;
  final Function(InventoryItemModel)? onSuccess;

  const InventoryItemPane({super.key, required this.user, this.item, this.onSuccess});

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
  InventoryCategoryModel? _selectedCategory;
  UomModel? _selectedUom;
  AccountModel? _inventoryAccount;
  AccountModel? _incomeAccount;
  AccountModel? _expenseAccount;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isInitializing = true;

  List<InventoryCategoryModel> _categories = [];
  List<UomModel> _uoms = [];
  List<AccountModel> _assetAccounts = [];
  List<AccountModel> _incomeAccounts = [];
  List<AccountModel> _expenseAccounts = [];

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
    _isActive = widget.item?.isActive ?? true;

    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final cats = await _inventoryService.getCategories(widget.user.companyId!).first;
      final uoms = await _inventoryService.getUoms(widget.user.companyId!).first;
      final accounts = await _accountService.getAccounts(widget.user.companyId!).first;

      if (mounted) {
        setState(() {
          _categories = cats;
          _uoms = uoms;
          _assetAccounts = accounts.where((a) => a.accountType == AccountType.asset).toList();
          _incomeAccounts = accounts.where((a) => a.accountType == AccountType.income).toList();
          _expenseAccounts = accounts.where((a) => 
            a.accountType == AccountType.expense || a.accountType == AccountType.costOfSales
          ).toList();

          if (widget.item != null) {
            _selectedCategory = _categories.cast<InventoryCategoryModel?>().firstWhere(
              (c) => c?.id == widget.item!.itemCategoryId,
              orElse: () => null,
            );
            _selectedUom = _uoms.cast<UomModel?>().firstWhere(
              (u) => u?.id == widget.item!.defaultUomId,
              orElse: () => null,
            );
            _inventoryAccount = _assetAccounts.cast<AccountModel?>().firstWhere(
              (a) => a?.id == widget.item!.inventoryAccountId,
              orElse: () => null,
            );
            _incomeAccount = _incomeAccounts.cast<AccountModel?>().firstWhere(
              (a) => a?.id == widget.item!.incomeAccountId,
              orElse: () => null,
            );
            _expenseAccount = _expenseAccounts.cast<AccountModel?>().firstWhere(
              (a) => a?.id == widget.item!.expenseAccountId,
              orElse: () => null,
            );
          }
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _salesPriceController.dispose();
    _purchasePriceController.dispose();
    _reorderController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final item = InventoryItemModel(
        id: widget.item?.id ?? const Uuid().v4(),
        companyId: widget.user.companyId!,
        itemCode: _codeController.text.trim(),
        itemName: _nameController.text.trim(),
        itemDescription: _descController.text.trim(),
        itemCategoryId: _selectedCategory?.id,
        itemType: _itemType,
        defaultUomId: _selectedUom?.id ?? '',
        salesPrice: double.tryParse(_salesPriceController.text) ?? 0,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
        inventoryAccountId: _inventoryAccount?.id,
        incomeAccountId: _incomeAccount?.id,
        expenseAccountId: _expenseAccount?.id,
        reorderLevel: double.tryParse(_reorderController.text) ?? 0,
        minimumStock: double.tryParse(_minStockController.text) ?? 0,
        maximumStock: double.tryParse(_maxStockController.text) ?? 0,
        isActive: _isActive,
        createdAt: widget.item?.createdAt ?? DateTime.now(),
      );

      await _inventoryService.addItem(item);
      if (widget.onSuccess != null) widget.onSuccess!(item);
      if (mounted) {
        Navigator.pop(context);
        showErpSuccess(
          context: context,
          title: 'Success',
          message: 'Item ${widget.item == null ? 'added' : 'updated'} successfully.',
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

    return ErpSidePane(
      title: widget.item == null ? 'Add New Item' : 'Edit Item',
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      saveLabel: widget.item == null ? 'Create Item' : 'Save Changes',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Identification', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _codeController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Item Code *', icon: Icons.qr_code),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Item Name *', icon: Icons.inventory),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<InventoryItemType>(
                    initialValue: _itemType,
                    items: InventoryItemType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _itemType = v!),
                    decoration: ErpFormStyle.inputDecoration(context, 'Item Type', icon: Icons.category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SearchableSelector<InventoryCategoryModel>(
                    labelText: 'Category',
                    items: _categories,
                    itemLabelBuilder: (c) => c.name,
                    onSelected: (val) => setState(() => _selectedCategory = val),
                    initialValue: _selectedCategory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SearchableSelector<UomModel>(
              labelText: 'Default Unit of Measure *',
              items: _uoms,
              itemLabelBuilder: (u) => u.uomName,
              onSelected: (val) => setState(() => _selectedUom = val),
              initialValue: _selectedUom,
              validator: (v) => _selectedUom == null ? 'Required' : null,
            ),
            
            const SizedBox(height: 32),
            Text('Pricing & Accounts', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salesPriceController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Sales Price', icon: Icons.sell_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Purchase Price', icon: Icons.shopping_cart_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_itemType == InventoryItemType.stock)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SearchableSelector<AccountModel>(
                  labelText: 'Inventory Account',
                  items: _assetAccounts,
                  itemLabelBuilder: (a) => a.accountName,
                  onSelected: (val) => setState(() => _inventoryAccount = val),
                  initialValue: _inventoryAccount,
                ),
              ),
            SearchableSelector<AccountModel>(
              labelText: 'Income Account',
              items: _incomeAccounts,
              itemLabelBuilder: (a) => a.accountName,
              onSelected: (val) => setState(() => _incomeAccount = val),
              initialValue: _incomeAccount,
            ),
            const SizedBox(height: 16),
            SearchableSelector<AccountModel>(
              labelText: 'Expense / COGS Account',
              items: _expenseAccounts,
              itemLabelBuilder: (a) => a.accountName,
              onSelected: (val) => setState(() => _expenseAccount = val),
              initialValue: _expenseAccount,
            ),

            const SizedBox(height: 32),
            Text('Stock Control', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Min Stock'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _reorderController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Reorder Level'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxStockController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Max Stock'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            SwitchListTile(
              title: const Text('Active Status', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Inactive items cannot be used in new transactions', style: TextStyle(fontSize: 12)),
              value: _isActive,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
