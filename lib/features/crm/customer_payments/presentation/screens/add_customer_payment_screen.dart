import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/features/invoices/models/invoice_model.dart';
import 'package:ledgixerp/features/invoices/services/invoice_service.dart';
import 'package:ledgixerp/features/banking/models/bank_account_model.dart';
import 'package:ledgixerp/features/banking/services/bank_account_service.dart';
import 'package:ledgixerp/features/crm/customer_payments/models/customer_payment_model.dart';
import 'package:ledgixerp/features/crm/customer_payments/services/customer_payment_service.dart';

class AddCustomerPaymentScreen extends StatefulWidget {
  final AppUser user;
  const AddCustomerPaymentScreen({super.key, required this.user});

  @override
  State<AddCustomerPaymentScreen> createState() => _AddCustomerPaymentScreenState();
}

class _AddCustomerPaymentScreenState extends State<AddCustomerPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = CustomerPaymentService();
  final _customerService = CustomerService();
  final _invoiceService = InvoiceService();
  final _bankService = BankAccountService();
  
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentNumber = 'Loading...';
  CustomerModel? _selectedCustomer;
  InvoiceModel? _selectedInvoice;
  BankAccountModel? _selectedBankAccount;
  DateTime _paymentDate = DateTime.now();
  CustomerPaymentMethod _paymentMethod = CustomerPaymentMethod.bank;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final number = await _paymentService.generateNextNumber(widget.user.companyId!);
    if (mounted) {
      setState(() => _paymentNumber = number);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }
    if (_selectedBankAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a bank/cash account')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payment = CustomerPaymentModel(
        id: '',
        companyId: widget.user.companyId!,
        paymentNumber: _paymentNumber,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        invoiceId: _selectedInvoice?.id,
        invoiceNumber: _selectedInvoice?.invoiceNumber,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer Payment'),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
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
                              decoration: const InputDecoration(labelText: 'Payment Number', border: OutlineInputBorder()),
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
                                  decoration: const InputDecoration(labelText: 'Select Customer', border: OutlineInputBorder()),
                                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCustomer = val;
                                      _selectedInvoice = null;
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
                            child: StreamBuilder<List<InvoiceModel>>(
                              stream: _invoiceService.getInvoices(widget.user.companyId!),
                              builder: (context, snapshot) {
                                final invoices = (snapshot.data ?? [])
                                    .where((inv) => inv.customerId == _selectedCustomer?.id && inv.status != InvoiceStatus.paid)
                                    .toList();
                                return DropdownButtonFormField<InvoiceModel>(
                                  initialValue: _selectedInvoice,
                                  decoration: const InputDecoration(labelText: 'Link to Invoice (Optional)', border: OutlineInputBorder()),
                                  items: invoices.map((inv) => DropdownMenuItem(
                                    value: inv,
                                    child: Text('${inv.invoiceNumber} (${NumberFormat('#,##0.00').format(inv.balanceDue)})'),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedInvoice = val),
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
                                decoration: const InputDecoration(labelText: 'Payment Date', border: OutlineInputBorder()),
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
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ ', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
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
                                  decoration: const InputDecoration(labelText: 'Deposit To (Bank/Cash)', border: OutlineInputBorder()),
                                  items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.accountName))).toList(),
                                  onChanged: (val) => setState(() => _selectedBankAccount = val),
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
                            child: DropdownButtonFormField<CustomerPaymentMethod>(
                              initialValue: _paymentMethod,
                              decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                              items: CustomerPaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase()))).toList(),
                              onChanged: (val) => setState(() => _paymentMethod = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _referenceController,
                              decoration: const InputDecoration(labelText: 'Reference #', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
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
