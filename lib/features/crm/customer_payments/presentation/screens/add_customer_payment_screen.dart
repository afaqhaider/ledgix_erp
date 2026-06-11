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
import 'package:ledgixerp/features/crm/customers/presentation/widgets/customer_pane.dart';
import 'package:ledgixerp/features/banking/presentation/widgets/bank_account_pane.dart';
import 'package:ledgixerp/features/accounting/journal/models/journal_entry_model.dart';
import 'package:ledgixerp/features/accounting/journal/services/journal_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/form_layout.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/widgets/posting_error_modal.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';
import 'package:ledgixerp/features/operations/jobs/services/job_service.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';

class AddCustomerPaymentScreen extends StatefulWidget {
  final AppUser user;
  final bool isPane;
  const AddCustomerPaymentScreen({
    super.key,
    required this.user,
    this.isPane = false,
  });

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
  final _jobService = JobService();
  final _settingsService = FinancialSettingsService();

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
  JobModel? _selectedJob;

  List<CustomerModel> _allCustomers = [];
  List<InvoiceModel> _allInvoices = [];
  List<JournalEntryModel> _allJVs = [];
  List<BankAccountModel> _allBankAccounts = [];
  List<JobModel> _activeJobs = [];
  bool _jobEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompany();
    _loadSettings();
    _listenToMasterData();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettings(widget.user.companyId!);
    if (mounted) {
      setState(() {
        _jobEnabled = settings.jobBasedAccountingEnabled;
      });
      if (_jobEnabled) {
        _jobService.getActiveJobs(widget.user.companyId!).listen((jobs) {
          if (mounted) setState(() => _activeJobs = jobs);
        });
      }
    }
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

  bool get _canPost {
    const highRoles = [
      UserRole.owner,
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.accountant,
      UserRole.generalManager,
    ];
    return highRoles.contains(widget.user.role);
  }

  Future<void> _save({bool shouldPost = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (shouldPost) {
      if (_selectedCustomer == null) {
        showErpError(
          context: context,
          title: 'Selection Required',
          message: 'Please select a customer before posting the receipt.',
        );
        return;
      }
      if (_selectedBankAccount == null) {
        showErpError(
          context: context,
          title: 'Account Required',
          message: 'Please select a bank/cash account.',
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final payment = CustomerPaymentModel(
        id: '',
        companyId: widget.user.companyId!,
        paymentNumber: 'AUTO',
        customerId: _selectedCustomer?.id ?? '',
        customerName: _selectedCustomer?.name ?? 'Draft Customer',
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
        bankAccountId: _selectedBankAccount?.id,
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
        isPosted: shouldPost && _canPost,
        approvalStatus: shouldPost ? (_canPost ? 'approved' : 'pending') : null,
        jobId: _selectedJob?.id,
        jobNumber: _selectedJob?.jobNumber,
        jobName: _selectedJob?.jobName,
      );

      await _paymentService.addPayment(
        payment,
        widget.user,
        shouldPost: shouldPost,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e, stack) {
      debugPrint('Error saving payment: $e');
      debugPrint(stack.toString());
      if (mounted) {
        if (shouldPost) {
          PostingErrorModal.show(
            context: context,
            title: 'Posting Failed',
            message:
                'An error occurred while trying to post the receipt. The transaction may not have been completed.',
            error: e,
          );
        } else {
          showErpError(context: context, error: e);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formContent = Form(
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
                    child: Text(DateFormat('dd-MMM-yyyy').format(_paymentDate)),
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
            onAdd: () => showErpSidePane(
              context: context,
              builder: CustomerPane(companyId: widget.user.companyId!),
            ),
            initialValue: _selectedCustomer,
          ),
          if (_jobEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            SearchableSelector<JobModel>(
              labelText: 'Linked Job (Optional)',
              items: _activeJobs,
              itemLabelBuilder: (j) => '${j.jobNumber} - ${j.jobName}',
              onSelected: (val) => setState(() => _selectedJob = val),
              initialValue: _selectedJob,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<ReceiptType>(
            value: _receiptType,
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
                  value: _paymentMethod,
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
              child: BankAccountPane(companyId: widget.user.companyId!),
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
          if (!widget.isPane) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _save(shouldPost: false),
                      child: const Text('Save Draft'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _save(shouldPost: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _canPost ? 'Save & Post' : 'Submit for Approval',
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (widget.isPane) {
      return ErpSidePane(
        title: 'Add New Receipt',
        onCancel: () => Navigator.pop(context),
        onSave: () => _save(shouldPost: true),
        isLoading: _isLoading,
        saveLabel: _canPost ? 'Save & Post' : 'Submit for Approval',
        extraActions: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => _save(shouldPost: false),
            child: const Text('Save Draft'),
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: formContent,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Receipt')),
      body: FormLayout(
        maxWidth: 640,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: formContent,
        ),
      ),
    );
  }
}
