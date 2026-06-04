import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/suppliers/services/bill_service.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';
import 'package:ledgixerp/features/suppliers/services/supplier_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/suppliers/presentation/widgets/add_supplier_dialog.dart';
import 'package:ledgixerp/features/inventory/models/product_model.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/settings/models/credit_term_model.dart';
import 'package:ledgixerp/features/settings/services/terms_service.dart';
import 'package:ledgixerp/features/settings/presentation/widgets/add_credit_term_dialog.dart';
import 'package:ledgixerp/features/inventory/presentation/widgets/add_product_dialog.dart';
import 'package:ledgixerp/core/models/attachment_model.dart';
import 'package:ledgixerp/core/widgets/attachment_section.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class AddBillScreen extends StatefulWidget {
  final AppUser user;
  final bool isPane;
  const AddBillScreen({super.key, required this.user, this.isPane = false});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billService = BillService();
  final _supplierService = SupplierService();
  final _accountService = AccountService();
  final _inventoryService = InventoryService();
  final _termsService = TermsService();

  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _billNumber = 'Loading...';
  SupplierModel? _selectedSupplier;
  CreditTermModel? _selectedTerm;
  DateTime _billDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  List<AttachmentModel> _attachments = [];

  List<SupplierModel> _allSuppliers = [];
  List<AccountModel> _allAccounts = [];
  List<ProductModel> _allProducts = [];
  List<CreditTermModel> _allTerms = [];
  final List<BillLineItemModel> _items = [];
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
          _allAccounts = accounts.where((a) => 
            a.accountType == AccountType.expense || 
            a.accountType == AccountType.asset || 
            a.accountType == AccountType.costOfSales ||
            a.accountType == AccountType.otherExpense
          ).toList();
        });
      }
    });
    _inventoryService.getProducts(widget.user.companyId!).listen((products) {
      if (mounted) setState(() => _allProducts = products);
    });
    _termsService.getCreditTerms(widget.user.companyId!).listen((terms) {
      if (mounted) {
        setState(() {
          _allTerms = terms;
          if (_selectedTerm == null) {
            _selectedTerm = terms.where((t) => t.isDefault).firstOrNull;
            if (_selectedTerm != null) {
              _updateDueDate();
            }
          }
        });
      }
    });
  }

  void _updateDueDate() {
    if (_selectedTerm != null) {
      setState(() {
        _dueDate = _billDate.add(Duration(days: _selectedTerm!.days));
      });
    }
  }

  Future<void> _loadInitialData() async {
    final number = await _billService.generateNextBillNumber(
      widget.user.companyId!,
    );
    if (mounted) {
      setState(() => _billNumber = number);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(
        BillLineItemModel(
          accountId: '',
          accountName: '',
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
    String? accountName,
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
      _items[index] = BillLineItemModel(
        productId: productId ?? item.productId,
        accountId: accountId ?? item.accountId,
        accountName: accountName ?? item.accountName,
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
      _items.fold(0, (sum, item) => sum + item.lineSubtotal);
  double get _totalVat => _items.fold(0, (sum, item) => sum + item.lineVat);
  double get _totalAmount => _totalSubtotal + _totalVat;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }

    if (_items.any((item) => item.accountId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All items must have an account selected'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bill = BillModel(
        id: '',
        companyId: widget.user.companyId!,
        billNumber: 'AUTO',
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.supplierName,
        billDate: _billDate,
        dueDate: _dueDate,
        items: _items,
        subtotal: _totalSubtotal,
        vatAmount: _totalVat,
        totalAmount: _totalAmount,
        balanceDue: _totalAmount,
        reference: _referenceController.text,
        notes: _notesController.text,
        attachments: _attachments,
        createdAt: DateTime.now(),
      );

      await _billService.addBill(bill);
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
    showDialog(
      context: context,
      builder: (context) =>
          AddSupplierDialog(companyId: widget.user.companyId!),
    );
  }

  void _showAddCreditTermDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCreditTermDialog(companyId: widget.user.companyId!),
    );
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(companyId: widget.user.companyId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill Information', style: ErpFormStyle.sectionHeaderStyle(context)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: ErpFormStyle.inputDecoration(context, 'Bill Number'),
                  child: Text(
                    'Next number: $_billNumber',
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
                      initialDate: _billDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _billDate = date);
                      _updateDueDate();
                    }
                  },
                  child: InputDecorator(
                    decoration: ErpFormStyle.inputDecoration(context, 'Bill Date', icon: Icons.calendar_today),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_billDate),
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
                  onSelected: (val) {
                    setState(() {
                      _selectedTerm = val;
                      _updateDueDate();
                    });
                  },
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
                      initialDate: _dueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _dueDate = date);
                  },
                  child: InputDecorator(
                    decoration: ErpFormStyle.inputDecoration(context, 'Due Date', icon: Icons.event),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_dueDate),
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceController,
            style: ErpFormStyle.inputStyle(context),
            decoration: ErpFormStyle.inputDecoration(context, 'Vendor Invoice # / Ref', icon: Icons.tag),
            validator: (v) => v == null || v.isEmpty ? 'Reference required' : null,
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
          Text('Notes & Attachments', style: ErpFormStyle.sectionHeaderStyle(context)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            style: ErpFormStyle.inputStyle(context),
            decoration: ErpFormStyle.inputDecoration(context, 'Notes / Terms'),
          ),
          const SizedBox(height: 16),
          AttachmentSection(
            companyId: widget.user.companyId!,
            folder: 'bills',
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
        title: 'New Purchase Bill',
        onCancel: () => Navigator.pop(context),
        onSave: _save,
        isLoading: _isLoading,
        saveLabel: 'Create Bill',
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Invoice (Bill)'),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Save Bill'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text('Product / Account', style: ErpFormStyle.labelStyle(context))),
              Expanded(flex: 1, child: Text('Qty', style: ErpFormStyle.labelStyle(context), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Unit Cost', style: ErpFormStyle.labelStyle(context), textAlign: TextAlign.center)),
              Expanded(flex: 1, child: Text('VAT%', style: ErpFormStyle.labelStyle(context), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Total', style: ErpFormStyle.labelStyle(context), textAlign: TextAlign.right)),
              const SizedBox(width: 40),
            ],
          ),
        ),
        ..._items.asMap().entries.map((entry) {
          int index = entry.key;
          BillLineItemModel item = entry.value;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
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
                      if (val is ProductModel) return '${val.sku} - ${val.name}';
                      if (val is AccountModel) return '${val.accountCode} - ${val.accountName}';
                      return '';
                    },
                    onSelected: (val) {
                      if (val is ProductModel) {
                        _updateItem(
                          index,
                          productId: val.id,
                          accountId: val.expenseAccountId ?? val.assetAccountId ?? '',
                          accountName: val.name,
                          desc: val.description ?? val.name,
                          price: val.costPrice,
                        );
                      } else if (val is AccountModel) {
                        _updateItem(
                          index,
                          accountId: val.id,
                          accountName: val.accountName,
                          desc: val.accountName,
                        );
                      }
                    },
                    addLabel: 'Add Product',
                    onAdd: _showAddProductDialog,
                    initialValue: item.productId != null 
                      ? _allProducts.where((p) => p.id == item.productId).firstOrNull
                      : _allAccounts.where((a) => a.id == item.accountId).firstOrNull,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, '').copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4)),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _updateItem(index, qty: double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, '').copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4)),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _updateItem(index, price: double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: item.vatRate.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, '').copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4)),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _updateItem(index, vat: double.tryParse(v) ?? 0),
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
                      style: ErpFormStyle.inputStyle(context).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white30, size: 18),
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
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', _totalSubtotal),
            const SizedBox(height: 12),
            _buildSummaryRow('VAT Amount', _totalVat),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Colors.white10),
            ),
            _buildSummaryRow('Total Amount', _totalAmount, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? ErpFormStyle.sectionHeaderStyle(context) : ErpFormStyle.labelStyle(context),
        ),
        Text(
          NumberFormat('#,##0.00').format(value),
          style: TextStyle(
            color: isBold ? Colors.blueAccent : Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
