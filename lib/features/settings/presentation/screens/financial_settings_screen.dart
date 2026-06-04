import 'package:flutter/material.dart';
import '../../../../core/auth/app_user.dart';
import '../../models/financial_settings_model.dart';
import '../../services/financial_settings_service.dart';

class FinancialSettingsScreen extends StatefulWidget {
  final AppUser user;

  const FinancialSettingsScreen({super.key, required this.user});

  @override
  State<FinancialSettingsScreen> createState() =>
      _FinancialSettingsScreenState();
}

class _FinancialSettingsScreenState extends State<FinancialSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FinancialSettingsService();
  bool _isLoading = true;
  String? _errorMessage;
  late FinancialSettingsModel _settings;

  // Controllers
  final _invoicePrefixController = TextEditingController();
  final _quotationPrefixController = TextEditingController();
  final _poPrefixController = TextEditingController();
  final _receiptPrefixController = TextEditingController();
  final _suppPayPrefixController = TextEditingController();
  final _journalPrefixController = TextEditingController();
  final _billPrefixController = TextEditingController();
  final _activePeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (widget.user.companyId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No company linked to this user.';
      });
      return;
    }

    try {
      final settings = await _service.getSettings(widget.user.companyId!);
      if (mounted) {
        setState(() {
          _settings = settings;
          _invoicePrefixController.text = settings.invoicePrefix;
          _quotationPrefixController.text = settings.quotationPrefix;
          _poPrefixController.text = settings.purchaseOrderPrefix;
          _receiptPrefixController.text = settings.receiptPrefix;
          _suppPayPrefixController.text = settings.supplierPaymentPrefix;
          _journalPrefixController.text = settings.journalPrefix;
          _billPrefixController.text = settings.billPrefix;
          _activePeriodController.text = settings.activeAccountingPeriod;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading settings: $e';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.user.companyId == null) return;

    setState(() => _isLoading = true);

    final updatedSettings = FinancialSettingsModel(
      companyId: widget.user.companyId!,
      financialYearStart: _settings.financialYearStart,
      financialYearEnd: _settings.financialYearEnd,
      activeAccountingPeriod: _activePeriodController.text,
      lockPastPeriods: _settings.lockPastPeriods,
      invoicePrefix: _invoicePrefixController.text,
      quotationPrefix: _quotationPrefixController.text,
      purchaseOrderPrefix: _poPrefixController.text,
      receiptPrefix: _receiptPrefixController.text,
      supplierPaymentPrefix: _suppPayPrefixController.text,
      journalPrefix: _journalPrefixController.text,
      billPrefix: _billPrefixController.text,
      nextInvoiceNumber: _settings.nextInvoiceNumber,
      nextQuotationNumber: _settings.nextQuotationNumber,
      nextPurchaseOrderNumber: _settings.nextPurchaseOrderNumber,
      nextReceiptNumber: _settings.nextReceiptNumber,
      nextSupplierPaymentNumber: _settings.nextSupplierPaymentNumber,
      nextJournalNumber: _settings.nextJournalNumber,
      nextBillNumber: _settings.nextBillNumber,
    );

    try {
      await _service.updateSettings(updatedSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Financial Settings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadSettings, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionHeader('Accounting Period'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _activePeriodController,
              decoration: const InputDecoration(
                labelText: 'Active Accounting Period (YYYY-MM)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(value)) {
                  return 'Use YYYY-MM format';
                }
                return null;
              },
            ),
            SwitchListTile(
              title: const Text('Lock Past Periods'),
              subtitle: const Text(
                'Prevent posting or editing transactions in previous months',
              ),
              value: _settings.lockPastPeriods,
              onChanged: (val) => setState(
                () => _settings = _settings.copyWith(lockPastPeriods: val),
              ),
            ),
            const Divider(height: 48),
            _buildSectionHeader('Document Numbering (Prefixes)'),
            const SizedBox(height: 16),
            _buildPrefixField('Invoice Prefix', _invoicePrefixController),
            _buildPrefixField('Quotation Prefix', _quotationPrefixController),
            _buildPrefixField('Purchase Order Prefix', _poPrefixController),
            _buildPrefixField(
              'Receipt Prefix',
              _receiptPrefixController,
            ),
            _buildPrefixField(
              'Supplier Payment Prefix',
              _suppPayPrefixController,
            ),
            _buildPrefixField(
              'Journal Voucher Prefix',
              _journalPrefixController,
            ),
            _buildPrefixField(
              'Vendor Bill Prefix',
              _billPrefixController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPrefixField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}
