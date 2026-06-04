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
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/suppliers/presentation/widgets/add_supplier_dialog.dart';
import 'package:ledgixerp/features/banking/presentation/widgets/add_bank_account_dialog.dart';

import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/theme/app_theme.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class AddSupplierPaymentScreen extends StatefulWidget {
  final AppUser user;
  final bool isPane;
  const AddSupplierPaymentScreen({super.key, required this.user, this.isPane = false});

  @override
  State<AddSupplierPaymentScreen> createState() =>
      _AddSupplierPaymentScreenState();
}

class _AddSupplierPaymentScreenState extends State<AddSupplierPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = SupplierPaymentService();
  final _supplierService = SupplierService();
  final _poService = PurchaseOrderService();
  final _bankService = BankAccountService();
  final _companyService = CompanyService();

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentNumber = 'Loading...';
  SupplierModel? _selectedSupplier;
  CompanyModel? _company;
  PurchaseOrderModel? _selectedPO;
  BankAccountModel? _selectedBankAccount;
  DateTime _paymentDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.bank;

  List<SupplierModel> _allSuppliers = [];
  List<PurchaseOrderModel> _allPOs = [];
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
    _supplierService.getSuppliers(widget.user.companyId!).listen((suppliers) {
      if (mounted) setState(() => _allSuppliers = suppliers);
    });
    _poService.getPurchaseOrders(widget.user.companyId!).listen((pos) {
      if (mounted) setState(() => _allPOs = pos);
    });
    _bankService.getBankAccounts(widget.user.companyId!).listen((accounts) {
      if (mounted) setState(() => _allBankAccounts = accounts);
    });
  }

  Future<void> _loadInitialData() async {
    final number = await _paymentService.generateNextPaymentNumber(
      widget.user.companyId!,
    );
    if (mounted) {
      setState(() => _paymentNumber = number);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
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
        paymentNumber: 'AUTO',
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.supplierName,
        purchaseOrderId: _selectedPO?.id,
        purchaseOrderNumber: _selectedPO?.poNumber,
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

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddSupplierDialog(companyId: widget.user.companyId!),
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
                  decoration: ErpFormStyle.inputDecoration(context, 'Payment Number'),
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
                    decoration: ErpFormStyle.inputDecoration(context, 'Payment Date', icon: Icons.calendar_today),
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
          SearchableSelector<SupplierModel>(
            labelText: 'Supplier',
            items: _allSuppliers,
            itemLabelBuilder: (s) => s.supplierName,
            onSelected: (val) {
              setState(() {
                _selectedSupplier = val;
                _selectedPO = null;
              });
            },
            addLabel: 'Add New Supplier',
            onAdd: _showAddSupplierDialog,
            initialValue: _selectedSupplier,
            validator: (v) => _selectedSupplier == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          SearchableSelector<PurchaseOrderModel>(
            labelText: 'Link to Purchase Order (Optional)',
            items: _allPOs
                .where((po) => po.supplierId == _selectedSupplier?.id)
                .toList(),
            itemLabelBuilder: (po) =>
                '${po.poNumber} (${AppFormatters.currency(po.totalAmount, symbol: _company?.baseCurrency)})',
            onSelected: (val) => setState(() => _selectedPO = val),
            addLabel: 'Create New PO',
            onAdd: () {},
            initialValue: _selectedPO,
          ),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<PaymentMethod>(
                  value: _paymentMethod,
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(context, 'Method'),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(
                        method.name.toUpperCase(),
                        style: ErpFormStyle.inputStyle(context),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchableSelector<BankAccountModel>(
            labelText: 'Paid From (Bank/Cash)',
            items: _allBankAccounts,
            itemLabelBuilder: (a) => a.accountName,
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
            decoration: ErpFormStyle.inputDecoration(context, 'Reference / Cheque #'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            style: ErpFormStyle.inputStyle(context),
            decoration: ErpFormStyle.inputDecoration(context, 'Notes'),
          ),
        ],
      ),
    );

    if (widget.isPane) {
      return ErpSidePane(
        title: 'Add Supplier Payment',
        onCancel: () => Navigator.pop(context),
        onSave: _save,
        isLoading: _isLoading,
        saveLabel: 'Save Payment',
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Supplier Payment')),
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
