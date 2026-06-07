import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/widgets/form_layout.dart';
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
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FormLayout(
                  maxWidth: 800,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Accounting Period'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _activePeriodController,
                        decoration: const InputDecoration(
                          labelText: 'Active Accounting Period (YYYY-MM)',
                          helperText: 'Controls which month is currently open for posting',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(value)) {
                            return 'Use YYYY-MM format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lock Past Periods', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                          'Prevent posting or editing transactions in previous months',
                        ),
                        value: _settings.lockPastPeriods,
                        onChanged: (val) => setState(
                          () =>
                              _settings = _settings.copyWith(lockPastPeriods: val),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Divider(),
                      ),
                      _buildSectionHeader('Document Numbering (Prefixes)'),
                      const SizedBox(height: 24),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 16,
                        childAspectRatio: 3.5,
                        children: [
                          _buildPrefixField('Invoice Prefix', _invoicePrefixController),
                          _buildPrefixField(
                            'Quotation Prefix',
                            _quotationPrefixController,
                          ),
                          _buildPrefixField(
                            'Purchase Order Prefix',
                            _poPrefixController,
                          ),
                          _buildPrefixField('Receipt Prefix', _receiptPrefixController),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Settings',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Configure accounting periods and document numbering',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
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
