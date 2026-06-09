import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/auth/app_user.dart';
import '../../../../widgets/erp_ui_components.dart';
import '../../../../widgets/form_layout.dart';
import '../../../../widgets/searchable_selector.dart';
import '../../../accounting/chart_of_accounts/account_model.dart';
import '../../../accounting/chart_of_accounts/account_service.dart';
import '../../../operations/jobs/models/job_model.dart';
import '../../../operations/jobs/services/job_service.dart';
import '../../../settings/services/financial_settings_service.dart';
import '../../models/expense_voucher_model.dart';
import '../../services/expense_voucher_service.dart';

class AddExpenseVoucherScreen extends StatefulWidget {
  final AppUser user;
  final bool isPane;

  const AddExpenseVoucherScreen({
    super.key,
    required this.user,
    this.isPane = false,
  });

  @override
  State<AddExpenseVoucherScreen> createState() => _AddExpenseVoucherScreenState();
}

class _AddExpenseVoucherScreenState extends State<AddExpenseVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ExpenseVoucherService();
  final _accountService = AccountService();
  final _jobService = JobService();
  final _settingsService = FinancialSettingsService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _jobEnabled = false;
  List<AccountModel> _bankAccounts = [];
  List<AccountModel> _expenseAccounts = [];
  List<JobModel> _activeJobs = [];

  DateTime _selectedDate = DateTime.now();
  final _descriptionController = TextEditingController();
  
  AccountModel? _selectedFromAccount;
  JobModel? _selectedJob;
  
  final List<ExpenseVoucherLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final companyId = widget.user.companyId!;
    try {
      final settings = await _settingsService.getSettings(companyId);
      final accounts = await _accountService.getAccounts(companyId).first;
      
      if (mounted) {
        setState(() {
          _jobEnabled = settings.jobBasedAccountingEnabled;
          _bankAccounts = accounts.where((a) => 
            a.allowPosting && 
            (a.accountCategory == AccountCategory.cash || a.accountCategory == AccountCategory.bank)
          ).toList();
          
          _expenseAccounts = accounts.where((a) => 
            a.allowPosting && 
            (a.accountType == AccountType.expense || a.accountType == AccountType.otherExpense || a.accountType == AccountType.costOfSales)
          ).toList();
          
          _isLoading = false;
        });
      }

      if (_jobEnabled) {
        final jobs = await _jobService.getActiveJobs(companyId).first;
        if (mounted) {
          setState(() {
            _activeJobs = jobs;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(ExpenseVoucherLine(
        accountId: '',
        accountName: '',
        description: _descriptionController.text,
        amount: 0.0,
        total: 0.0,
      ));
    });
  }

  void _updateLine(int index, {String? accId, String? accName, String? desc, double? amount, bool? hasVat}) {
    final line = _lines[index];
    final newAmount = amount ?? line.amount;
    final newHasVat = hasVat ?? line.hasVat;
    final vatAmt = newHasVat ? newAmount * 0.05 : 0.0;

    setState(() {
      _lines[index] = ExpenseVoucherLine(
        accountId: accId ?? line.accountId,
        accountName: accName ?? line.accountName,
        description: desc ?? line.description,
        amount: newAmount,
        hasVat: newHasVat,
        vatAmount: vatAmt,
        total: newAmount + vatAmt,
        jobId: line.jobId,
        jobNumber: line.jobNumber,
        jobName: line.jobName,
      );
    });
  }

  double get _totalSubtotal => _lines.fold(0.0, (sum, l) => sum + l.amount);
  double get _totalVat => _lines.fold(0.0, (sum, l) => sum + l.vatAmount);
  double get _totalAmount => _totalSubtotal + _totalVat;

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty || _lines.any((l) => l.accountId.isEmpty)) {
      showErpError(context: context, title: 'Incomplete Voucher', message: 'Please add at least one line with an account.');
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final voucherNumber = await _service.generateVoucherNumber(widget.user.companyId!);
      
      final voucher = ExpenseVoucherModel(
        id: const Uuid().v4(),
        companyId: widget.user.companyId!,
        voucherNumber: voucherNumber,
        date: _selectedDate,
        fromAccountId: _selectedFromAccount!.id,
        fromAccountName: _selectedFromAccount!.accountName,
        description: _descriptionController.text,
        lines: _lines,
        totalAmount: _totalSubtotal,
        totalVat: _totalVat,
        status: ExpenseVoucherStatus.draft,
        createdByUserId: widget.user.uid,
        createdAt: DateTime.now(),
        jobId: _selectedJob?.id,
        jobNumber: _selectedJob?.jobNumber,
        jobName: _selectedJob?.jobName,
      );

      await _service.createVoucher(voucher);
      await _service.postVoucher(widget.user.companyId!, voucher.id, widget.user.uid);

      if (mounted) {
        Navigator.pop(context);
        showErpSuccess(context: context, title: 'Success', message: 'Voucher posted successfully');
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final formContent = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: FormLayout(
        maxWidth: 1000,
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
                            child: _buildDatePicker(
                              label: 'Voucher Date',
                              selectedDate: _selectedDate,
                              onTap: (date) => setState(() => _selectedDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SearchableSelector<AccountModel>(
                              labelText: 'Paid From (Bank/Cash)',
                              items: _bankAccounts,
                              itemLabelBuilder: (a) => a.accountName,
                              onSelected: (val) => setState(() => _selectedFromAccount = val),
                              initialValue: _selectedFromAccount,
                              validator: (v) => _selectedFromAccount == null ? 'Required' : null,
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
                      TextFormField(
                        controller: _descriptionController,
                        style: ErpFormStyle.inputStyle(context),
                        decoration: ErpFormStyle.inputDecoration(context, 'General Description', icon: Icons.description_outlined),
                        maxLines: 2,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Expense Lines', style: ErpFormStyle.sectionHeaderStyle(context)),
              const SizedBox(height: 16),
              _buildLinesTable(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add),
                label: const Text('Add Line'),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Spacer(),
                  _buildSummarySection(),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isPane) {
      return ErpSidePane(
        title: 'New Expense Voucher',
        onCancel: () => Navigator.pop(context),
        onSave: _saveVoucher,
        isLoading: _isSaving,
        saveLabel: 'Save & Post',
        child: formContent,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Expense Voucher'),
        actions: [
          ElevatedButton(
            onPressed: _isSaving ? null : _saveVoucher,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Post'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: formContent,
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
        decoration: ErpFormStyle.inputDecoration(context, label, icon: Icons.calendar_today),
        child: Text(DateFormat('yyyy-MM-dd').format(selectedDate), style: ErpFormStyle.inputStyle(context)),
      ),
    );
  }

  Widget _buildLinesTable() {
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
              Expanded(flex: 3, child: Text('Expense Account', style: ErpFormStyle.labelStyle(context))),
              Expanded(flex: 3, child: Text('Description', style: ErpFormStyle.labelStyle(context))),
              Expanded(flex: 1, child: Text('Amount', style: ErpFormStyle.labelStyle(context), textAlign: TextAlign.right)),
              Expanded(flex: 1, child: Text('VAT', style: ErpFormStyle.labelStyle(context), textAlign: TextAlign.center)),
              Expanded(flex: 1, child: Text('Total', style: ErpFormStyle.labelStyle(context), textAlign: TextAlign.right)),
              const SizedBox(width: 40),
            ],
          ),
        ),
        ..._lines.asMap().entries.map((entry) {
          int index = entry.key;
          ExpenseVoucherLine line = entry.value;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SearchableSelector<AccountModel>(
                    labelText: '',
                    items: _expenseAccounts,
                    itemLabelBuilder: (a) => '${a.accountCode} - ${a.accountName}',
                    onSelected: (val) => _updateLine(index, accId: val?.id, accName: val?.accountName),
                    initialValue: line.accountId.isEmpty ? null : _expenseAccounts.firstWhere((a) => a.id == line.accountId),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: line.description,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, ''),
                    onChanged: (v) => _updateLine(index, desc: v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: line.amount == 0 ? '' : line.amount.toString(),
                    style: ErpFormStyle.inputStyle(context),
                    textAlign: TextAlign.right,
                    decoration: ErpFormStyle.inputDecoration(context, ''),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _updateLine(index, amount: double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Checkbox(
                    value: line.hasVat,
                    onChanged: (v) => _updateLine(index, hasVat: v),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      NumberFormat('#,##0.00').format(line.total),
                      textAlign: TextAlign.right,
                      style: ErpFormStyle.inputStyle(context),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _lines.removeAt(index)),
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
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', _totalSubtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('VAT', _totalVat),
          Divider(height: 24, color: theme.dividerColor),
          _buildSummaryRow('Total', _totalAmount, isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBold ? ErpFormStyle.sectionHeaderStyle(context) : ErpFormStyle.labelStyle(context)),
        Text(
          NumberFormat('#,##0.00').format(value),
          style: TextStyle(
            color: isBold ? Colors.blueAccent : null,
            fontWeight: isBold ? FontWeight.bold : null,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
