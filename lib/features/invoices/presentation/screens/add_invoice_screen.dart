import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/invoices/services/invoice_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/crm/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/settings/models/credit_term_model.dart';
import 'package:ledgixerp/features/settings/services/terms_service.dart';
import 'package:ledgixerp/core/models/attachment_model.dart';
import 'package:ledgixerp/core/widgets/attachment_section.dart';

import 'package:ledgixerp/features/settings/presentation/widgets/add_credit_term_dialog.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/features/inventory/presentation/widgets/add_inventory_item_pane.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/form_layout.dart';

class AddInvoiceScreen extends StatefulWidget {
  final AppUser user;
  final bool isPane;
  const AddInvoiceScreen({super.key, required this.user, this.isPane = false});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceService = InvoiceService();
  final _customerService = CustomerService();
  final _accountService = AccountService();
  final _inventoryService = InventoryService();
  final _termsService = TermsService();

  String _previewNumber = 'Loading...';
  CustomerModel? _selectedCustomer;
  CreditTermModel? _selectedTerm;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  List<AttachmentModel> _attachments = [];

  List<CustomerModel> _allCustomers = [];
  List<AccountModel> _allAccounts = [];
  List<InventoryItemModel> _allProducts = [];
  List<CreditTermModel> _allTerms = [];
  final List<InvoiceLineItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _addItem();
    _listenToMasterData();
  }

  void _listenToMasterData() {
    _customerService.getCustomers(widget.user.companyId!).listen((customers) {
      if (mounted) setState(() => _allCustomers = customers);
    });
    _accountService.getAccounts(widget.user.companyId!).listen((accounts) {
      if (mounted) {
        setState(() {
          _allAccounts = accounts
              .where(
                (a) =>
                    a.accountType == AccountType.income ||
                    a.accountType == AccountType.otherIncome,
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
        _dueDate = _invoiceDate.add(Duration(days: _selectedTerm!.days));
      });
    }
  }

  Future<void> _loadInitialData() async {
    final number = await _invoiceService.previewNextInvoiceNumber(
      widget.user.companyId!,
    );
    if (mounted) {
      setState(() => _previewNumber = number);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(
        InvoiceLineItemModel(
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
    String? unit,
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
      _items[index] = InvoiceLineItemModel(
        productId: productId ?? item.productId,
        accountId: accountId ?? item.accountId,
        accountName: accountName ?? item.accountName,
        description: desc ?? item.description,
        unit: unit ?? item.unit,
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
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
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
      final invoice = InvoiceModel(
        id: '',
        companyId: widget.user.companyId!,
        invoiceNumber: 'AUTO',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        items: _items,
        subtotal: _totalSubtotal,
        vatAmount: _totalVat,
        totalAmount: _totalAmount,
        balanceDue: _totalAmount,
        createdAt: DateTime.now(),
        attachments: _attachments,
      );

      await _invoiceService.addInvoice(invoice);
      if (mounted) {
        if (widget.isPane) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
      }
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

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddCustomerDialog(companyId: widget.user.companyId!),
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
    SidePanel.show(
      context: context,
      title: 'New Inventory Item',
      child: AddInventoryItemPane(user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Sales Invoice'),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Invoice'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormLayout(
          maxWidth: 1100,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: ErpFormStyle.inputDecoration(
                                  context,
                                  'Invoice Number',
                                ),
                                child: Text(
                                  'Next number: $_previewNumber',
                                  style: ErpFormStyle.inputStyle(context)
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: SearchableSelector<CustomerModel>(
                                labelText: 'Select Customer',
                                items: _allCustomers,
                                itemLabelBuilder: (c) => c.name,
                                onSelected: (val) =>
                                    setState(() => _selectedCustomer = val),
                                addLabel: 'Add New Customer',
                                onAdd: _showAddCustomerDialog,
                                initialValue: _selectedCustomer,
                                validator: (v) => _selectedCustomer == null
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(
                                label: 'Invoice Date',
                                selectedDate: _invoiceDate,
                                onTap: (date) {
                                  setState(() => _invoiceDate = date);
                                  _updateDueDate();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SearchableSelector<CreditTermModel>(
                                labelText: 'Payment Terms',
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDatePicker(
                                label: 'Due Date',
                                selectedDate: _dueDate,
                                onTap: (date) =>
                                    setState(() => _dueDate = date),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Invoice Items',
                  style: ErpFormStyle.sectionHeaderStyle(context),
                ),
                const SizedBox(height: 16),
                _buildItemsTable(),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
                const SizedBox(height: 32),
                AttachmentSection(
                  companyId: widget.user.companyId!,
                  folder: 'invoices',
                  onAttachmentsChanged: (attachments) {
                    _attachments = attachments;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const Spacer(), _buildSummarySection()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onTap,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) onTap(date);
      },
      child: InputDecorator(
        decoration: ErpFormStyle.inputDecoration(
          context,
          label,
          icon: Icons.calendar_today,
        ),
        child: Text(
          DateFormat('yyyy-MM-dd').format(selectedDate),
          style: ErpFormStyle.inputStyle(context),
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(2),
        5: IntrinsicColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Product / Account',
                style: ErpFormStyle.labelStyle(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Qty', style: ErpFormStyle.labelStyle(context)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Unit Price',
                style: ErpFormStyle.labelStyle(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('VAT%', style: ErpFormStyle.labelStyle(context)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Total',
                textAlign: TextAlign.right,
                style: ErpFormStyle.labelStyle(context),
              ),
            ),
            const Padding(padding: EdgeInsets.all(8), child: Text('')),
          ],
        ),
        ..._items.asMap().entries.map((entry) {
          int index = entry.key;
          InvoiceLineItemModel item = entry.value;

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
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
                        accountId: val.incomeAccountId ?? '',
                        accountName: val.itemName,
                        desc: val.itemName,
                        unit: val.defaultUomId,
                        price: val.salesPrice,
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
                      ? _allProducts
                            .where((p) => p.id == item.productId)
                            .firstOrNull
                      : _allAccounts
                            .where((a) => a.id == item.accountId)
                            .firstOrNull,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(context, ''),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      _updateItem(index, qty: double.tryParse(v) ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: item.unitPrice.toString(),
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(context, ''),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      _updateItem(index, price: double.tryParse(v) ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: item.vatRate.toString(),
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(context, ''),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      _updateItem(index, vat: double.tryParse(v) ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  NumberFormat('#,##0.00').format(item.lineTotal),
                  textAlign: TextAlign.right,
                  style: ErpFormStyle.inputStyle(context),
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
          );
        }),
      ],
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
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
          const SizedBox(height: 8),
          _buildSummaryRow('VAT Amount', _totalVat),
          Divider(height: 24, color: theme.dividerColor),
          _buildSummaryRow('Total Amount', _totalAmount, isBold: true),
        ],
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
