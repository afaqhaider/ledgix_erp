import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import 'package:ledgixerp/features/suppliers/services/bill_service.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';
import 'package:ledgixerp/features/suppliers/services/supplier_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_service.dart';
import 'package:ledgixerp/widgets/searchable_selector.dart';
import 'package:ledgixerp/features/suppliers/presentation/widgets/supplier_pane.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/settings/models/credit_term_model.dart';
import 'package:ledgixerp/features/settings/services/terms_service.dart';
import 'package:ledgixerp/features/settings/presentation/widgets/add_credit_term_dialog.dart';
import 'package:ledgixerp/features/inventory/presentation/widgets/inventory_item_pane.dart';
import 'package:ledgixerp/core/models/attachment_model.dart';
import 'package:ledgixerp/core/widgets/attachment_section.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/widgets/form_layout.dart';
import 'package:ledgixerp/widgets/posting_error_modal.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/operations/jobs/models/job_model.dart';
import 'package:ledgixerp/features/operations/jobs/services/job_service.dart';
import 'package:ledgixerp/features/settings/services/financial_settings_service.dart';

class AddBillScreen extends StatefulWidget {
  final AppUser user;
  final bool isPane;
  final BillModel? initialBill;

  const AddBillScreen({
    super.key,
    required this.user,
    this.isPane = false,
    this.initialBill,
  });

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billService = BillService();
  final _supplierService = SupplierService();
  final _accountService = AccountService();
  final _inventoryService = InventoryService();
  final _termsService = TermsService();
  final _jobService = JobService();
  final _settingsService = FinancialSettingsService();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();

  String _previewNumber = 'Loading...';
  SupplierModel? _selectedSupplier;
  CreditTermModel? _selectedTerm;
  DateTime _billDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  List<AttachmentModel> _attachments = [];

  List<SupplierModel> _allSuppliers = [];
  List<AccountModel> _allAccounts = [];
  List<InventoryItemModel> _allProducts = [];
  List<CreditTermModel> _allTerms = [];
  List<JobModel> _activeJobs = [];
  JobModel? _selectedJob;
  bool _jobEnabled = false;

  final List<BillLineItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBill != null) {
      final bill = widget.initialBill!;
      _billDate = bill.billDate;
      _dueDate = bill.dueDate;
      _attachments = List.from(bill.attachments);
      _items.addAll(bill.items);
      _selectedSupplier = SupplierModel(
        id: bill.supplierId,
        companyId: bill.companyId,
        supplierName: bill.supplierName,
        supplierCode: '',
        openingBalanceType: BalanceType.credit,
        email: '',
        phone: '',
        trnVatNumber: '',
        address: '',
        createdAt: DateTime.now(),
      );
      _previewNumber = bill.billNumber;
      _notesController.text = bill.notes ?? '';
      _referenceController.text = bill.reference ?? '';
      _selectedJob = bill.jobId != null ? JobModel(
        id: bill.jobId!,
        companyId: bill.companyId,
        jobNumber: bill.jobNumber ?? '',
        jobName: bill.jobName ?? '',
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: '',
      ) : null;
    } else {
      _addItem();
    }
    _loadInitialData();
    _listenToMasterData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _listenToMasterData() {
    _supplierService.getSuppliers(widget.user.companyId!).listen((suppliers) {
      if (mounted) setState(() => _allSuppliers = suppliers);
    });
    _accountService.getAccounts(widget.user.companyId!).listen((accounts) {
      if (mounted) {
        setState(() {
          _allAccounts = accounts
              .where(
                (a) =>
                    a.accountType == AccountType.expense ||
                    a.accountType == AccountType.costOfSales,
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
        _dueDate = _billDate.add(Duration(days: _selectedTerm!.days));
      });
    }
  }

  Future<void> _loadInitialData() async {
    final companyId = widget.user.companyId!;
    final number = await _billService.previewNextBillNumber(companyId);
    final settings = await _settingsService.getSettings(companyId);
    
    if (mounted) {
      setState(() {
        _previewNumber = number;
        _jobEnabled = settings.jobBasedAccountingEnabled;
      });
      
      if (_jobEnabled) {
        _jobService.getActiveJobs(companyId).listen((jobs) {
          if (mounted) setState(() => _activeJobs = jobs);
        });
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(
        BillLineItemModel(
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
      _items[index] = BillLineItemModel(
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
      if (_selectedSupplier == null) {
        showErpError(
          context: context,
          title: 'Selection Required',
          message: 'Please select a supplier before posting the bill.',
        );
        return;
      }
      if (_items.isEmpty || _items.any((item) => item.accountId.isEmpty)) {
        showErpError(
          context: context,
          title: 'Account Required',
          message: 'All items must have a posting account selected.',
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final bill = BillModel(
        id: widget.initialBill?.id ?? '',
        companyId: widget.user.companyId!,
        billNumber: widget.initialBill?.billNumber ?? 'AUTO',
        supplierId: _selectedSupplier?.id ?? '',
        supplierName: _selectedSupplier?.supplierName ?? 'Draft Supplier',
        billDate: _billDate,
        dueDate: _dueDate,
        items: _items,
        subtotal: _totalSubtotal,
        vatAmount: _totalVat,
        totalAmount: _totalAmount,
        balanceDue: _totalAmount,
        notes: _notesController.text,
        reference: _referenceController.text,
        createdAt: widget.initialBill?.createdAt ?? DateTime.now(),
        attachments: _attachments,
        status: shouldPost
            ? (_canPost ? BillStatus.posted : BillStatus.pendingApproval)
            : (widget.initialBill?.status ?? BillStatus.draft),
        jobId: _selectedJob?.id,
        jobNumber: _selectedJob?.jobNumber,
        jobName: _selectedJob?.jobName,
        isPosted: widget.initialBill?.isPosted ?? false,
      );

      if (widget.initialBill == null) {
        await _billService.addBill(bill, widget.user, shouldPost: shouldPost);
      } else {
        await _billService.updateBill(bill, widget.user, shouldPost: shouldPost);
      }
      if (mounted) {
        if (widget.isPane) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e, stack) {
      debugPrint('Error saving bill: $e');
      debugPrint(stack.toString());
      if (mounted) {
        if (shouldPost) {
          PostingErrorModal.show(
            context: context,
            title: 'Posting Failed',
            message:
                'An error occurred while trying to post the bill. The transaction may not have been completed.',
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

  void _showAddSupplierDialog() {
    showErpSidePane(
      context: context,
      builder: SupplierPane(companyId: widget.user.companyId!),
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
    showErpSidePane(
      context: context,
      builder: InventoryItemPane(user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formContent = SingleChildScrollView(
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
                                'Bill Number',
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
                            child: SearchableSelector<SupplierModel>(
                              labelText: 'Select Supplier',
                              items: _allSuppliers,
                              itemLabelBuilder: (s) => s.supplierName,
                              onSelected: (val) =>
                                  setState(() => _selectedSupplier = val),
                              addLabel: 'Add New Supplier',
                              onAdd: _showAddSupplierDialog,
                              initialValue: _selectedSupplier,
                              validator: (v) =>
                                  _selectedSupplier == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      if (_jobEnabled) ...[
                        const SizedBox(height: 16),
                        SearchableSelector<JobModel>(
                          labelText: 'Linked Job (Optional)',
                          items: _activeJobs,
                          itemLabelBuilder: (j) => '${j.jobNumber} - ${j.jobName}',
                          onSelected: (val) => setState(() => _selectedJob = val),
                          initialValue: _selectedJob,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDatePicker(
                              label: 'Bill Date',
                              selectedDate: _billDate,
                              onTap: (date) {
                                setState(() => _billDate = date);
                                _updateDueDate();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
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
                            flex: 2,
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
              Text(
                'Bill Items',
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
                folder: 'bills',
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
    );

    if (widget.isPane) {
      return ErpSidePane(
        title: 'Create New Bill',
        onCancel: () => Navigator.pop(context),
        onSave: () => _save(shouldPost: _canPost),
        isLoading: _isLoading,
        saveLabel: _canPost ? 'Save & Post' : 'Submit for Approval',
        extraActions: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => _save(shouldPost: false),
            child: const Text('Save Draft'),
          ),
        ],
        child: formContent,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Bill'),
        actions: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => _save(shouldPost: false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
            ),
            child: const Text('Save Draft'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _save(shouldPost: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(_canPost ? 'Save & Post' : 'Submit for Approval'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: formContent,
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black12,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Product / Account',
                  style: ErpFormStyle.labelStyle(context),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Qty',
                  style: ErpFormStyle.labelStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Unit Price',
                  style: ErpFormStyle.labelStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'VAT%',
                  style: ErpFormStyle.labelStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Total',
                  style: ErpFormStyle.labelStyle(context),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        ..._items.asMap().entries.map((entry) {
          int index = entry.key;
          BillLineItemModel item = entry.value;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
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
                          accountId:
                              val.expenseAccountId ??
                              val.inventoryAccountId ??
                              '',
                          accountName: val.itemName,
                          desc: val.itemName,
                          price: val.purchasePrice,
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
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, ''),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _updateItem(index, qty: double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, ''),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _updateItem(index, price: double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: item.vatRate.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.center,
                    decoration: ErpFormStyle.inputDecoration(context, ''),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _updateItem(index, vat: double.tryParse(v) ?? 0),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      NumberFormat('#,##0.00').format(item.lineTotal),
                      textAlign: TextAlign.right,
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
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
