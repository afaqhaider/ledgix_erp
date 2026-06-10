import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/features/quotations/models/quotation_model.dart';
import 'package:ledgixerp/features/quotations/services/quotation_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/crm/customers/presentation/widgets/customer_pane.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/settings/models/payment_term_model.dart';
import 'package:ledgixerp/features/settings/services/terms_service.dart';
import 'package:ledgixerp/features/settings/presentation/widgets/add_payment_term_dialog.dart';
import 'package:ledgixerp/features/inventory/presentation/widgets/inventory_item_pane.dart';
import 'package:ledgixerp/core/models/attachment_model.dart';
import 'package:ledgixerp/core/widgets/attachment_section.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/form_layout.dart';

class AddQuotationScreen extends StatefulWidget {
  final AppUser user;
  const AddQuotationScreen({super.key, required this.user});

  @override
  State<AddQuotationScreen> createState() => _AddQuotationScreenState();
}

class _AddQuotationScreenState extends State<AddQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quoService = QuotationService();
  final _customerService = CustomerService();
  final _accountService = AccountService();
  final _inventoryService = InventoryService();
  final _termsService = TermsService();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String _previewNumber = 'Loading...';
  CustomerModel? _selectedCustomer;
  PaymentTermModel? _selectedTerm;
  DateTime _quoDate = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 15));
  List<AttachmentModel> _attachments = [];

  List<CustomerModel> _allCustomers = [];
  List<AccountModel> _allAccounts = [];
  List<InventoryItemModel> _allProducts = [];
  List<PaymentTermModel> _allTerms = [];
  final List<QuotationLineItemModel> _items = [];
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
    _termsService.getPaymentTerms(widget.user.companyId!).listen((terms) {
      if (mounted) {
        setState(() {
          _allTerms = terms;
          if (_selectedTerm == null) {
            _selectedTerm = terms.where((t) => t.isDefault).firstOrNull;
            if (_selectedTerm != null) {
              _updateValidUntilDate();
            }
          }
        });
      }
    });
  }

  void _updateValidUntilDate() {
    if (_selectedTerm != null) {
      setState(() {
        _validUntil = _quoDate.add(Duration(days: _selectedTerm!.days));
      });
    }
  }

  Future<void> _loadInitialData() async {
    final number = await _quoService.previewNextQuotationNumber(
      widget.user.companyId!,
    );
    if (mounted) {
      setState(() => _previewNumber = number);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(
        QuotationLineItemModel(
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
      _items[index] = QuotationLineItemModel(
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
      _items.fold(0.0, (sum, item) => sum + item.lineSubtotal);
  double get _totalVat => _items.fold(0.0, (sum, item) => sum + item.lineVat);
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
      final quo = QuotationModel(
        id: '',
        companyId: widget.user.companyId!,
        quotationNumber: 'AUTO',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        quotationDate: _quoDate,
        validUntilDate: _validUntil,
        items: _items,
        subtotal: _totalSubtotal,
        vatAmount: _totalVat,
        totalAmount: _totalAmount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        termsAndConditions: _termsController.text.trim().isEmpty
            ? null
            : _termsController.text.trim(),
        attachments: _attachments,
        createdAt: DateTime.now(),
      );

      await _quoService.addQuotation(quo);
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

  void _showAddCustomerDialog() {
    showErpSidePane(
      context: context,
      builder: CustomerPane(companyId: widget.user.companyId!),
    );
  }

  void _showAddPaymentTermDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddPaymentTermDialog(companyId: widget.user.companyId!),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Sales Quotation'),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Quotation'),
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
                              flex: 3,
                              child: InputDecorator(
                                decoration: ErpFormStyle.inputDecoration(
                                  context,
                                  'Document Number',
                                ),
                                child: Text(
                                  'Next: $_previewNumber',
                                  style: ErpFormStyle.inputStyle(context)
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
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
                              flex: 2,
                              child: _buildDatePicker(
                                label: 'Quotation Date',
                                selectedDate: _quoDate,
                                onTap: (date) {
                                  setState(() => _quoDate = date);
                                  _updateValidUntilDate();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: SearchableSelector<PaymentTermModel>(
                                labelText: 'Payment Terms',
                                items: _allTerms,
                                itemLabelBuilder: (t) => t.name,
                                onSelected: (val) {
                                  setState(() {
                                    _selectedTerm = val;
                                    _updateValidUntilDate();
                                  });
                                },
                                addLabel: 'Add New Term',
                                onAdd: _showAddPaymentTermDialog,
                                initialValue: _selectedTerm,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildDatePicker(
                                label: 'Valid Until',
                                selectedDate: _validUntil,
                                onTap: (date) =>
                                    setState(() => _validUntil = date),
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
                  'Quotation Items',
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
                  folder: 'quotations',
                  onAttachmentsChanged: (attachments) {
                    _attachments = attachments;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            style: ErpFormStyle.inputStyle(context),
                            decoration: ErpFormStyle.inputDecoration(
                              context,
                              'Notes',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _termsController,
                            maxLines: 2,
                            style: ErpFormStyle.inputStyle(context),
                            decoration: ErpFormStyle.inputDecoration(
                              context,
                              'Terms & Conditions',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    _buildSummarySection(),
                  ],
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
          QuotationLineItemModel item = entry.value;

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
