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
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/core/services/document_number_service.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/widgets/form_layout.dart';

class AddCustomerPaymentScreen extends StatefulWidget {
  final AppUser user;
  const AddCustomerPaymentScreen({super.key, required this.user});

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
  final _docNumberService = DocumentNumberService();

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  CustomerModel? _selectedCustomer;
  CompanyModel? _company;
  dynamic _selectedRef;
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
      // Consume number on save
      final nextNumber = await _docNumberService.getNextNumber(
        widget.user.companyId!,
        'receipt',
      );

      final payment = CustomerPaymentModel(
        id: '',
        companyId: widget.user.companyId!,
        paymentNumber: nextNumber,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        receiptType: _receiptType,
        invoiceId: _selectedRef is InvoiceModel
            ? _selectedRef.id
            : (_selectedRef is JournalEntryModel ? _selectedRef.id : null),
        invoiceNumber: _selectedRef is InvoiceModel
            ? _selectedRef.invoiceNumber
            : (_selectedRef is JournalEntryModel
                  ? _selectedRef.reference
                  : null),
        allocations: _selectedRef is InvoiceModel
            ? [
                PaymentAllocation(
                  invoiceId: _selectedRef.id,
                  invoiceNumber: _selectedRef.invoiceNumber,
                  amount: double.tryParse(_amountController.text) ?? 0.0,
                ),
              ]
            : [],
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

  @override
  Widget build(BuildContext context) {
    return FormLayout(
      maxWidth: 640,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                        labelText: 'Receipt Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd-MMM-yyyy').format(_paymentDate),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SearchableSelector<CustomerModel>(
              labelText: 'Customer',
              items: _allCustomers,
              itemLabelBuilder: (c) => c.name,
              onSelected: (val) => setState(() {
                _selectedCustomer = val;
                _selectedRef = null;
              }),
              addLabel: 'Add New Customer',
              onAdd: () => SidePanel.show(
                context: context,
                title: 'Add Customer',
                child: AddCustomerDialog(companyId: widget.user.companyId!),
              ),
              initialValue: _selectedCustomer,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ReceiptType>(
              initialValue: _receiptType,
              decoration: const InputDecoration(
                labelText: 'Receipt Type',
                border: OutlineInputBorder(),
              ),
              items: ReceiptType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (val) => setState(() {
                _receiptType = val!;
                _selectedRef = null;
              }),
            ),
            if (_receiptType == ReceiptType.againstRef) ...[
              const SizedBox(height: AppSpacing.md),
              SearchableSelector<dynamic>(
                labelText: 'Select Reference',
                items: [
                  ..._allInvoices.where(
                    (inv) =>
                        inv.customerId == _selectedCustomer?.id &&
                        inv.status != InvoiceStatus.paid,
                  ),
                  ..._allJVs.where(
                    (jv) => jv.reference.toLowerCase().contains('credit'),
                  ),
                ],
                itemLabelBuilder: (val) => val is InvoiceModel
                    ? 'Inv: ${val.invoiceNumber} | Due: ${AppFormatters.currency(val.balanceDue, symbol: _company?.baseCurrency)}'
                    : 'JV: ${val.reference}',
                onSelected: (val) => setState(() => _selectedRef = val),
                initialValue: _selectedRef,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${_company?.baseCurrency ?? 'AED'} ',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<CustomerPaymentMethod>(
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Method',
                      border: OutlineInputBorder(),
                    ),
                    items: CustomerPaymentMethod.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _paymentMethod = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SearchableSelector<BankAccountModel>(
              labelText: 'Mode of Payment',
              items: _allBankAccounts,
              itemLabelBuilder: (a) =>
                  '${a.accountName} (${a.bankName ?? 'Cash'})',
              onSelected: (val) => setState(() => _selectedBankAccount = val),
              initialValue: _selectedBankAccount,
              onAdd: () => SidePanel.show(
                context: context,
                title: 'Add Bank Account',
                child: AddBankAccountDialog(companyId: widget.user.companyId!),
              ),
              addLabel: 'Add Bank Account',
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference #',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Internal Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Receipt'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
