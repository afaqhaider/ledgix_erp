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
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/core/services/document_number_service.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/form_layout.dart';

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
  final _docNumberService = DocumentNumberService();

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

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
      final nextNumber = await _docNumberService.getNextNumber(
        widget.user.companyId!,
        'payment',
      );

      final payment = SupplierPaymentModel(
        id: '',
        companyId: widget.user.companyId!,
        paymentNumber: nextNumber,
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
                      labelText: 'Payment Date',
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
          SearchableSelector<SupplierModel>(
            labelText: 'Supplier',
            items: _allSuppliers,
            itemLabelBuilder: (s) => s.supplierName,
            onSelected: (val) => setState(() {
              _selectedSupplier = val;
              _selectedPO = null;
            }),
            addLabel: 'Add New Supplier',
            onAdd: () => SidePanel.show(
              context: context,
              title: 'Add Supplier',
              child: AddSupplierDialog(companyId: widget.user.companyId!),
            ),
            initialValue: _selectedSupplier,
          ),
          const SizedBox(height: AppSpacing.md),
          SearchableSelector<PurchaseOrderModel>(
            labelText: 'Link to Purchase Order (Optional)',
            items: _allPOs
                .where((po) => po.supplierId == _selectedSupplier?.id)
                .toList(),
            itemLabelBuilder: (po) =>
                '${po.poNumber} (${AppFormatters.currency(po.totalAmount, symbol: _company?.baseCurrency)})',
            onSelected: (val) => setState(() => _selectedPO = val),
            initialValue: _selectedPO,
          ),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<PaymentMethod>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Method',
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentMethod.values
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method.name.toUpperCase()),
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
            labelText: 'Paid From (Bank/Cash)',
            items: _allBankAccounts,
            itemLabelBuilder: (a) => a.accountName,
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
              labelText: 'Reference / Cheque #',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          if (!widget.isPane) ...[
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
                    : const Text('Save Payment'),
              ),
            ),
          ],
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
        child: formContent,
      );
    }

    return FormLayout(
      maxWidth: 640,
      child: formContent,
    );
  }
}
