import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ledgixerp/widgets/form_layout.dart';
import '../../../../core/auth/app_user.dart';
import '../../models/financial_settings_model.dart';
import '../../services/financial_settings_service.dart';

class DocsPrefixScreen extends StatefulWidget {
  final AppUser user;
  const DocsPrefixScreen({super.key, required this.user});

  @override
  State<DocsPrefixScreen> createState() => _DocsPrefixScreenState();
}

class _DocsPrefixScreenState extends State<DocsPrefixScreen> {
  final _service = FinancialSettingsService();
  bool _isLoading = true;
  late FinancialSettingsModel _settings;

  final _invoicePrefixController = TextEditingController();
  final _quotationPrefixController = TextEditingController();
  final _poPrefixController = TextEditingController();
  final _billPrefixController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.getSettings(widget.user.companyId!);
    if (mounted) {
      setState(() {
        _settings = settings;
        _invoicePrefixController.text = settings.invoicePrefix;
        _quotationPrefixController.text = settings.quotationPrefix;
        _poPrefixController.text = settings.purchaseOrderPrefix;
        _billPrefixController.text = settings.billPrefix;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final updated = _settings.copyWith(
      invoicePrefix: _invoicePrefixController.text,
      quotationPrefix: _quotationPrefixController.text,
      purchaseOrderPrefix: _poPrefixController.text,
      billPrefix: _billPrefixController.text,
    );
    await _service.updateSettings(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document prefixes updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              FormLayout(
                maxWidth: 600,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    _buildPrefixField('Bill Prefix', _billPrefixController),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Prefixes'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  'Document Prefixes',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Customize numbering prefixes for sales and purchase documents',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefixField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
