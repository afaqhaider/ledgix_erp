import 'package:flutter/material.dart';
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Document Prefixes')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPrefixField('Invoice Prefix', _invoicePrefixController),
          _buildPrefixField('Quotation Prefix', _quotationPrefixController),
          _buildPrefixField('Purchase Order Prefix', _poPrefixController),
          _buildPrefixField('Bill Prefix', _billPrefixController),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
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
      ),
    );
  }
}
