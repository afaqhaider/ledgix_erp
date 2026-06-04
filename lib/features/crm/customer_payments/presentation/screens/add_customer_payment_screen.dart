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
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/crm/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:ledgixerp/features/banking/presentation/widgets/add_bank_account_dialog.dart';

import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/services/journal_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';

import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/theme/app_theme.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class AddCustomerPaymentScreen extends StatefulWidget {
  final AppUser user;
  final bool isPane;
  const AddCustomerPaymentScreen({super.key, required this.user, this.isPane = false});

  @override
  State<AddCustomerPaymentScreen> createState() =>
      _AddCustomerPaymentScreenState();
}

class _AddCustomerPaymentScreenState extends State<AddCustomerPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = CustomerPaymentService();
  final _customerService = CustomerService();
  final _invoiceService = InvoiceService();
  final _bankService = BankAccountService();
  final _journalService = JournalService();
  final _companyService = CompanyService();

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentNumber = 'Loading...';
  CustomerModel? _selectedCustomer;
  CompanyModel? _company;
  dynamic _selectedRef; // Can be InvoiceModel or JournalEntryModel
  BankAccountModel? _selectedBankAccount;
  DateTime _paymentDate = DateTime.now();
  CustomerPaymentMethod _paymentMethod = CustomerPaymentMethod.bankTransfer;
  ReceiptType _receiptType = ReceiptType.againstRef;

  List<CustomerModel> _allCustomers = [];
  List<InvoiceModel> _allInvoices = [];
  List<JournalEntryModel> _allJVs = [];
  List<BankAccountModel> _allBankAccounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadCompany();
    _listenToMasterData();
  }

  void _loadCompany() {
    _companyService.getCompany(widget.user.companyId!).listen((company) {
      if (mounted) setState(() => _company = company);
    });
  }

  void _listenToMasterData() {
    _customerService.getCustomers(widget.user.companyId!).listen((customers) {
      if (mounted) setState(() => _allCustomers = customers);
    });
    _invoiceService.getInvoices(widget.user.companyId!).listen((invoices) {
      if (mounted) setState(() => _allInvoices = invoices);
    });
    _journalService.getJournalEntries(widget.user.companyId!).listen((jvs) {
      if (mounted) setState(() => _allJVs = jvs);
    });
    _bankService.getBankAccounts(widget.user.companyId!).listen((accounts) {
      if (mounted) setState(() => _allBankAccounts = accounts);
    });
  }

  Future<void> _loadInitialData() async {
    final number = await _paymentService.generateNextNumber(
      widget.user.companyId!,
    );
    if (mounted) {
      setState(() => _paymentNumber = number);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
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
      final payment = CustomerPaymentModel(
        id: '',
        companyId: widget.user.companyId!,
        paymentNumber: 'AUTO',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        receiptType: _receiptType,
        invoiceId: _selectedRef is InvoiceModel ? _selectedRef.id : (_selectedRef is JournalEntryModel ? _selectedRef.id : null),
        invoiceNumber: _selectedRef is InvoiceModel ? _selectedRef.invoiceNumber : (_selectedRef is JournalEntryModel ? _selectedRef.reference : null),
        allocations: _selectedRef is InvoiceModel ? [PaymentAllocation(invoiceId: _selectedRef.id, invoiceNumber: _selectedRef.invoiceNumber, amount: double.tryParse(_amountController.text) ?? 0.0)] : [],
        bankAccountId: _selectedBankAccount!.id,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        referenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _paymentService.addPayment(payment);
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Error saving receipt: $e');
      debugPrint(stack.toString());
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

  void _showAddBankAccountDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddBankAccountDialog(companyId: widget.user.companyId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('General Information', style: ErpFormStyle.sectionHeaderStyle(context)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: ErpFormStyle.inputDecoration(context, 'Receipt Number'),
                  child: Text(
                    'Next number: $_paymentNumber',
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
                      initialDate: _paymentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _paymentDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: ErpFormStyle.inputDecoration(context, 'Receipt Date', icon: Icons.calendar_today),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_paymentDate),
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchableSelector<CustomerModel>(
            labelText: 'Customer',
            items: _allCustomers,
            itemLabelBuilder: (c) => c.name,
            onSelected: (val) {
              setState(() {
                _selectedCustomer = val;
                _selectedRef = null;
              });
            },
            addLabel: 'Add New Customer',
            onAdd: _showAddCustomerDialog,
            initialValue: _selectedCustomer,
            validator: (v) => _selectedCustomer == null ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          Text('Reference & Allocation', style: ErpFormStyle.sectionHeaderStyle(context)),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReceiptType>(
            value: _receiptType,
            style: ErpFormStyle.inputStyle(context),
            decoration: ErpFormStyle.inputDecoration(context, 'Receipt Type'),
            dropdownColor: Theme.of(context).colorScheme.surface,
            items: ReceiptType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(
                      t.label,
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _receiptType = val!;
                _selectedRef = null;
              });
            },
          ),
          if (_receiptType == ReceiptType.againstRef) ...[
            const SizedBox(height: 16),
            SearchableSelector<dynamic>(
              labelText: 'Select Reference (Invoice/JV)',
              items: [
                ..._allInvoices.where(
                  (inv) =>
                      inv.customerId == _selectedCustomer?.id &&
                      inv.status != InvoiceStatus.paid,
                ),
                ..._allJVs.where((jv) {
                  final customerName = _selectedCustomer?.name.toLowerCase();
                  return jv.reference.toLowerCase().contains('credit') || 
                         (customerName != null && jv.description.toLowerCase().contains(customerName));
                }),
              ],
              itemLabelBuilder: (val) {
                if (val is InvoiceModel) {
                  return 'Inv: ${val.invoiceNumber} | Total: ${AppFormatters.currency(val.totalAmount, symbol: _company?.baseCurrency)} | Due: ${AppFormatters.currency(val.balanceDue, symbol: _company?.baseCurrency)}';
                }
                if (val is JournalEntryModel) {
                  return 'JV: ${val.reference} - ${val.description}';
                }
                return '';
              },
              onSelected: (val) => setState(() => _selectedRef = val),
              addLabel: 'Create New Invoice',
              onAdd: () {},
              initialValue: _selectedRef,
            ),
          ],
          const SizedBox(height: 24),
          Text('Payment Details', style: ErpFormStyle.sectionHeaderStyle(context)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(
                    context,
                    'Amount',
                    prefixText: '${_company?.baseCurrency ?? 'AED'} ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<CustomerPaymentMethod>(
                  value: _paymentMethod,
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(context, 'Method'),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: CustomerPaymentMethod.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m == CustomerPaymentMethod.bankTransfer ? 'Bank Transfer' : m.name.toUpperCase(),
                            style: ErpFormStyle.inputStyle(context),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchableSelector<BankAccountModel>(
            labelText: 'Mode of Payment',
            items: _allBankAccounts,
            itemLabelBuilder: (a) => '${a.accountName} (${a.bankName ?? 'Cash'})',
            onSelected: (val) => setState(() => _selectedBankAccount = val),
            addLabel: 'Add Bank Account',
            onAdd: _showAddBankAccountDialog,
            initialValue: _selectedBankAccount,
            validator: (v) => _selectedBankAccount == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceController,
            style: ErpFormStyle.inputStyle(context),
            decoration: ErpFormStyle.inputDecoration(context, 'Reference #'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            style: ErpFormStyle.inputStyle(context),
            decoration: ErpFormStyle.inputDecoration(context, 'Internal Notes'),
          ),
        ],
      ),
    );

    if (widget.isPane) {
      return ErpSidePane(
        title: 'Add Receipt',
        onCancel: () => Navigator.pop(context),
        onSave: _save,
        isLoading: _isLoading,
        saveLabel: 'Save Receipt',
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
        actions: [
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Save Receipt'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: content,
          ),
        ),
      ),
    );
  }
}
