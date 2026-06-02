import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';
import 'package:ledgixerp/features/suppliers/services/supplier_service.dart';
import 'package:ledgixerp/features/purchase_orders/models/purchase_order_model.dart';
import 'package:ledgixerp/features/purchase_orders/services/purchase_order_service.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/services/bank_account_service.dart';
import 'package:ledgixerp/features/supplier_payments/models/supplier_payment_model.dart';
import 'package:ledgixerp/features/supplier_payments/services/supplier_payment_service.dart';

class AddSupplierPaymentScreen extends StatefulWidget {
  final AppUser user;
  const AddSupplierPaymentScreen({super.key, required this.user});

  @override
  State<AddSupplierPaymentScreen> createState() => _AddSupplierPaymentScreenState();
}

class _AddSupplierPaymentScreenState extends State<AddSupplierPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = SupplierPaymentService();
  final _supplierService = SupplierService();
  final _poService = PurchaseOrderService();
  final _bankService = BankAccountService();
  
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentNumber = 'Loading...';
  SupplierModel? _selectedSupplier;
  PurchaseOrderModel? _selectedPO;
  BankAccountModel? _selectedBankAccount;
  DateTime _paymentDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.bank;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final number = await _paymentService.generateNextPaymentNumber(widget.user.companyId!);
    if (mounted) {
      setState(() => _paymentNumber = number);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }
    if (_selectedBankAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank/cash account')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payment = SupplierPaymentModel(
        id: '',
        companyId: widget.user.companyId!,
        paymentNumber: _paymentNumber,
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.supplierName,
        purchaseOrderId: _selectedPO?.id,
        purchaseOrderNumber: _selectedPO?.poNumber,
        bankAccountId: _selectedBankAccount!.id,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _paymentService.addPayment(payment);
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
        title: const Text('Add Supplier Payment'),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Payment'),
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
                              initialValue: _paymentNumber,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Payment Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: StreamBuilder<List<SupplierModel>>(
                              stream: _supplierService.getSuppliers(widget.user.companyId!),
                              builder: (context, snapshot) {
                                final suppliers = snapshot.data ?? [];
                                return DropdownButtonFormField<SupplierModel>(
                                  initialValue: _selectedSupplier,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Supplier',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: suppliers.map((s) {
                                    return DropdownMenuItem(value: s, child: Text(s.supplierName));
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedSupplier = val;
                                      _selectedPO = null; // Reset PO when supplier changes
                                    });
                                  },
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
                            child: _selectedSupplier == null
                                ? const IgnorePointer(
                                    child: Opacity(
                                      opacity: 0.5,
                                      child: TextField(
                                        decoration: InputDecoration(
                                          labelText: 'Link to Purchase Order (Optional)',
                                          border: OutlineInputBorder(),
                                          hintText: 'Select supplier first',
                                        ),
                                      ),
                                    ),
                                  )
                                : StreamBuilder<List<PurchaseOrderModel>>(
                                    stream: _poService.getPurchaseOrders(widget.user.companyId!),
                                    builder: (context, snapshot) {
                                      final allPOs = snapshot.data ?? [];
                                      final supplierPOs = allPOs
                                          .where((po) => po.supplierId == _selectedSupplier!.id)
                                          .toList();
                                      return DropdownButtonFormField<PurchaseOrderModel>(
                                        initialValue: _selectedPO,
                                        decoration: const InputDecoration(
                                          labelText: 'Link to Purchase Order (Optional)',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: supplierPOs.map((po) {
                                          return DropdownMenuItem(
                                            value: po,
                                            child: Text('${po.poNumber} (${NumberFormat('#,##0.00').format(po.totalAmount)})'),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setState(() => _selectedPO = val),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _paymentDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) setState(() => _paymentDate = date);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Payment Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(DateFormat('yyyy-MM-dd').format(_paymentDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v!.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) return 'Invalid amount';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StreamBuilder<List<BankAccountModel>>(
                              stream: _bankService.getBankAccounts(widget.user.companyId!),
                              builder: (context, snapshot) {
                                final accounts = snapshot.data ?? [];
                                return DropdownButtonFormField<BankAccountModel>(
                                  initialValue: _selectedBankAccount,
                                  decoration: const InputDecoration(
                                    labelText: 'Paid From (Bank/Cash)',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: accounts.map((a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a.accountName),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedBankAccount = val),
                                  validator: (v) => v == null ? 'Required' : null,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<PaymentMethod>(
                              initialValue: _paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Payment Method',
                                border: OutlineInputBorder(),
                              ),
                              items: PaymentMethod.values.map((method) {
                                return DropdownMenuItem(
                                  value: method,
                                  child: Text(method.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _paymentMethod = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference / Cheque # (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
