import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/invoices/services/invoice_service.dart';

class AddInvoiceScreen extends StatefulWidget {
  final AppUser user;
  const AddInvoiceScreen({super.key, required this.user});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceService = InvoiceService();
  final _customerService = CustomerService();

  String _invoiceNumber = 'Loading...';
  CustomerModel? _selectedCustomer;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  
  final List<InvoiceLineItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _addItem(); // Start with one empty item
  }

  Future<void> _loadInitialData() async {
    final number = await _invoiceService.generateNextInvoiceNumber(widget.user.companyId!);
    if (mounted) {
      setState(() => _invoiceNumber = number);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceLineItemModel(
        description: '',
        quantity: 1,
        unitPrice: 0,
        vatRate: 5, // Default 5%
        lineSubtotal: 0,
        lineVat: 0,
        lineTotal: 0,
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
    }
  }

  void _updateItem(int index, {String? desc, double? qty, double? price, double? vat}) {
    final item = _items[index];
    final newQty = qty ?? item.quantity;
    final newPrice = price ?? item.unitPrice;
    final newVatRate = vat ?? item.vatRate;
    
    final subtotal = newQty * newPrice;
    final vatAmt = subtotal * (newVatRate / 100);
    
    setState(() {
      _items[index] = InvoiceLineItemModel(
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

  double get _totalSubtotal => _items.fold(0, (sum, item) => sum + item.lineSubtotal);
  double get _totalVat => _items.fold(0, (sum, item) => sum + item.lineVat);
  double get _totalAmount => _totalSubtotal + _totalVat;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final invoice = InvoiceModel(
        id: '',
        companyId: widget.user.companyId!,
        invoiceNumber: _invoiceNumber,
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
      );

      await _invoiceService.addInvoice(invoice);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Invoice'),
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
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _invoiceNumber,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Invoice Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: StreamBuilder<List<CustomerModel>>(
                              stream: _customerService.getCustomers(widget.user.companyId!),
                              builder: (context, snapshot) {
                                final customers = snapshot.data ?? [];
                                return DropdownButtonFormField<CustomerModel>(
                                  initialValue: _selectedCustomer,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Customer',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: customers.map((c) {
                                    return DropdownMenuItem(value: c, child: Text(c.name));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedCustomer = val),
                                  validator: (v) => v == null ? 'Required' : null,
                                );
                              },
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
                              onTap: (date) => setState(() => _invoiceDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDatePicker(
                              label: 'Due Date',
                              selectedDate: _dueDate,
                              onTap: (date) => setState(() => _dueDate = date),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Invoice Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildItemsTable(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
              const SizedBox(height: 32),
              _buildSummarySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime selectedDate, required Function(DateTime) onTap}) {
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
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
      ),
    );
  }

  Widget _buildItemsTable() {
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
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.all(8), child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('VAT%', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('')),
          ],
        ),
        ..._items.asMap().entries.map((entry) {
          int index = entry.key;
          InvoiceLineItemModel item = entry.value;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: item.description,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (v) => _updateItem(index, desc: v),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateItem(index, qty: double.tryParse(v) ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: item.unitPrice.toString(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateItem(index, price: double.tryParse(v) ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  initialValue: item.vatRate.toString(),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateItem(index, vat: double.tryParse(v) ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(NumberFormat('#,##0.00').format(item.lineTotal), textAlign: TextAlign.right),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeItem(index),
              ),
            ],
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
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', _totalSubtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('VAT Amount', _totalVat),
            const Divider(height: 24),
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
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          NumberFormat('#,##0.00').format(value),
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14),
        ),
      ],
    );
  }
}
