import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';
import 'package:ledgixerp/features/suppliers/services/supplier_service.dart';
import 'package:ledgixerp/features/purchase_orders/models/purchase_order_model.dart';
import 'package:ledgixerp/features/purchase_orders/services/purchase_order_service.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/suppliers/presentation/widgets/supplier_pane.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/settings/models/credit_term_model.dart';
import 'package:ledgixerp/features/settings/services/terms_service.dart';
import 'package:ledgixerp/features/settings/presentation/widgets/add_credit_term_dialog.dart';
import 'package:ledgixerp/features/inventory/presentation/widgets/inventory_item_pane.dart';
import 'package:ledgixerp/core/models/attachment_model.dart';
import 'package:ledgixerp/core/widgets/attachment_section.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class AddPurchaseOrderScreen extends StatefulWidget {
  final AppUser user;
  final bool isPane;
  const AddPurchaseOrderScreen({
    super.key,
    required this.user,
    this.isPane = false,
  });

  @override
  State<AddPurchaseOrderScreen> createState() => _AddPurchaseOrderScreenState();
}

class _AddPurchaseOrderScreenState extends State<AddPurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _poService = PurchaseOrderService();
  final _supplierService = SupplierService();
  final _accountService = AccountService();
  final _inventoryService = InventoryService();
  final _termsService = TermsService();
  final _notesController = TextEditingController();

  String _poNumber = 'Loading...';
  SupplierModel? _selectedSupplier;
  CreditTermModel? _selectedTerm;
  DateTime _poDate = DateTime.now();
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  List<AttachmentModel> _attachments = [];

  List<SupplierModel> _allSuppliers = [];
  List<AccountModel> _allAccounts = [];
  List<InventoryItemModel> _allProducts = [];
  List<CreditTermModel> _allTerms = [];
  final List<POLineItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _addItem();
    _listenToMasterData();
  }

  void _listenToMasterData() {
    _supplierService.getSuppliers(widget.user.companyId!).listen((suppliers) {
      if (mounted) setState(() => _allSuppliers = suppliers);
    });
    _accountService.getAccounts(widget.user.companyId!).listen((accounts) {
      if (mounted) {
        setState(() {
          _allAccounts = accounts
              .where(
                (a) =>
                    a.accountType == AccountType.expense ||
                    a.accountType == AccountType.asset ||
                    a.accountType == AccountType.costOfSales,
              )
              .toList();
        });
      }
    });
    _inventoryService.getInventoryItems(widget.user.companyId!).listen((
      products,
    ) {
      if (mounted) setState(() => _allProducts = products);
    });
    _termsService.getCreditTerms(widget.user.companyId!).listen((terms) {
      if (mounted) {
        setState(() {
          _allTerms = terms;
          _selectedTerm ??= terms.where((t) => t.isDefault).firstOrNull;
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    final number = await _poService.generateNextPONumber(
      widget.user.companyId!,
    );
    if (mounted) {
      setState(() => _poNumber = number);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(
        POLineItemModel(
          description: '',
          quantity: 1,
          unitPrice: 0,
          vatRate: 5,
          lineSubtotal: 0,
          lineVat: 0,
          lineTotal: 0,
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
    }
  }

  void _updateItem(
    int index, {
    String? productId,
    String? accountId,
    String? desc,
    double? qty,
    double? price,
    double? vat,
  }) {
    final item = _items[index];
    final newQty = qty ?? item.quantity;
    final newPrice = price ?? item.unitPrice;
    final newVatRate = vat ?? item.vatRate;

    final subtotal = newQty * newPrice;
    final vatAmt = subtotal * (newVatRate / 100);

    setState(() {
      _items[index] = POLineItemModel(
        productId: productId ?? item.productId,
        accountId: accountId ?? item.accountId,
        description: desc ?? item.description,
        quantity: newQty,
        unitPrice: newPrice,
        vatRate: newVatRate,
        lineSubtotal: subtotal,
        lineVat: vatAmt,
        lineTotal: subtotal + vatAmt,
      );
    });
  }

  double get _totalSubtotal =>
      _items.fold(0.0, (sum, item) => sum + item.lineSubtotal);
  double get _totalVat => _items.fold(0.0, (sum, item) => sum + item.lineVat);
  double get _totalAmount => _totalSubtotal + _totalVat;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final po = PurchaseOrderModel(
        id: '',
        companyId: widget.user.companyId!,
        poNumber: 'AUTO',
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.supplierName,
        poDate: _poDate,
        expectedDeliveryDate: _deliveryDate,
        items: _items,
        subtotal: _totalSubtotal,
        vatAmount: _totalVat,
        totalAmount: _totalAmount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        attachments: _attachments,
        createdAt: DateTime.now(),
      );

      await _poService.addPurchaseOrder(po);
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

  void _showAddSupplierDialog() {
    showErpSidePane(
      context: context,
      builder: SupplierPane(companyId: widget.user.companyId!),
    );
  }

  void _showAddCreditTermDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddCreditTermDialog(companyId: widget.user.companyId!),
    );
  }

  void _showAddProductDialog() {
    showErpSidePane(
      context: context,
      builder: InventoryItemPane(user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PO Information',
            style: ErpFormStyle.sectionHeaderStyle(context),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: ErpFormStyle.inputDecoration(
                    context,
                    'PO Number',
                  ),
                  child: Text(
                    'Next number: $_poNumber',
                    style: ErpFormStyle.inputStyle(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _poDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _poDate = date);
                  },
                  child: InputDecorator(
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'PO Date',
                      icon: Icons.calendar_today,
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_poDate),
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchableSelector<SupplierModel>(
            labelText: 'Supplier',
            items: _allSuppliers,
            itemLabelBuilder: (s) => s.supplierName,
            onSelected: (val) => setState(() => _selectedSupplier = val),
            addLabel: 'Add New Supplier',
            onAdd: _showAddSupplierDialog,
            initialValue: _selectedSupplier,
            validator: (v) => _selectedSupplier == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SearchableSelector<CreditTermModel>(
                  labelText: 'Credit Terms',
                  items: _allTerms,
                  itemLabelBuilder: (t) => t.name,
                  onSelected: (val) => setState(() => _selectedTerm = val),
                  addLabel: 'Add New Term',
                  onAdd: _showAddCreditTermDialog,
                  initialValue: _selectedTerm,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _deliveryDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _deliveryDate = date);
                  },
                  child: InputDecorator(
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Delivery Date',
                      icon: Icons.local_shipping_outlined,
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_deliveryDate),
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Line Items', style: ErpFormStyle.sectionHeaderStyle(context)),
          const SizedBox(height: 16),
          _buildItemsTable(),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Line Item', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
          ),
          const SizedBox(height: 32),
          Text(
            'Notes & Attachments',
            style: ErpFormStyle.sectionHeaderStyle(context),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            style: ErpFormStyle.inputStyle(context),
            decoration: ErpFormStyle.inputDecoration(
              context,
              'Internal Notes / Remarks',
            ),
          ),
          const SizedBox(height: 16),
          AttachmentSection(
            companyId: widget.user.companyId!,
            folder: 'purchase_orders',
            onAttachmentsChanged: (attachments) {
              _attachments = attachments;
            },
          ),
          const SizedBox(height: 32),
          _buildSummarySection(),
        ],
      ),
    );

    if (widget.isPane) {
      return ErpSidePane(
        title: 'New Purchase Order',
        onCancel: () => Navigator.pop(context),
        onSave: _save,
        isLoading: _isLoading,
        saveLabel: 'Create PO',
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Purchase Order'),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Save PO'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Product / Account',
                  style: ErpFormStyle.labelStyle(context),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qty',
                  style: ErpFormStyle.labelStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Unit Price',
                  style: ErpFormStyle.labelStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'VAT%',
                  style: ErpFormStyle.labelStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Total',
                  style: ErpFormStyle.labelStyle(context),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        ..._items.asMap().entries.map((entry) {
          int index = entry.key;
          POLineItemModel item = entry.value;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SearchableSelector<dynamic>(
                    labelText: '',
                    items: [..._allProducts, ..._allAccounts],
                    itemLabelBuilder: (val) {
                      if (val is InventoryItemModel) {
                        return '${val.itemCode} - ${val.itemName}';
                      }
                      if (val is AccountModel) {
                        return '${val.accountCode} - ${val.accountName}';
                      }
                      return '';
                    },
                    onSelected: (val) {
                      if (val is InventoryItemModel) {
                        _updateItem(
                          index,
                          productId: val.id,
                          accountId:
                              val.expenseAccountId ??
                              val.inventoryAccountId ??
                              '',
                          desc: val.itemName,
                          price: val.purchasePrice,
                        );
                      } else if (val is AccountModel) {
                        _updateItem(
                          index,
                          accountId: val.id,
                          desc: val.accountName,
                        );
                      }
                    },
                    addLabel: 'Add Product',
                    onAdd: _showAddProductDialog,
                    initialValue: item.productId != null
                        ? _allProducts
                              .where((p) => p.id == item.productId)
                              .firstOrNull
                        : _allAccounts
                              .where((a) => a.id == item.accountId)
                              .firstOrNull,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, '')
                        .copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                        ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _updateItem(index, qty: double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, '')
                        .copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                        ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _updateItem(index, price: double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: item.vatRate.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, '')
                        .copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                        ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _updateItem(index, vat: double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      NumberFormat('#,##0.00').format(item.lineTotal),
                      textAlign: TextAlign.right,
                      style: ErpFormStyle.inputStyle(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.iconTheme.color?.withValues(alpha: 0.3),
                    size: 18,
                  ),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', _totalSubtotal),
            const SizedBox(height: 12),
            _buildSummaryRow('VAT Amount', _totalVat),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: theme.dividerColor),
            ),
            _buildSummaryRow('Total Amount', _totalAmount, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? ErpFormStyle.sectionHeaderStyle(context)
              : ErpFormStyle.labelStyle(context),
        ),
        Text(
          NumberFormat('#,##0.00').format(value),
          style: TextStyle(
            color: isBold ? Colors.blueAccent : theme.colorScheme.onSurface,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
