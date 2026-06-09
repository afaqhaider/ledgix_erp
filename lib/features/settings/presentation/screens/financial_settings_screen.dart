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
  final _jobPrefixController = TextEditingController();
  final _expenseVoucherPrefixController = TextEditingController();

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
          _jobPrefixController.text = settings.jobPrefix;
          _expenseVoucherPrefixController.text = settings.expenseVoucherPrefix;
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

    final updatedSettings = _settings.copyWith(
      invoicePrefix: _invoicePrefixController.text,
      quotationPrefix: _quotationPrefixController.text,
      purchaseOrderPrefix: _poPrefixController.text,
      receiptPrefix: _receiptPrefixController.text,
      supplierPaymentPrefix: _suppPayPrefixController.text,
      journalPrefix: _journalPrefixController.text,
      billPrefix: _billPrefixController.text,
      jobPrefix: _jobPrefixController.text,
      expenseVoucherPrefix: _expenseVoucherPrefixController.text,
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
                          _buildPrefixField(
                            'Invoice Prefix',
                            _invoicePrefixController,
                          ),
                          _buildPrefixField(
                            'Quotation Prefix',
                            _quotationPrefixController,
                          ),
                          _buildPrefixField(
                            'Purchase Order Prefix',
                            _poPrefixController,
                          ),
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
                          _buildPrefixField(
                            'Job Prefix',
                            _jobPrefixController,
                          ),
                          _buildPrefixField(
                            'Expense Voucher Prefix',
                            _expenseVoucherPrefixController,
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
