import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';

class CompanySetupScreen extends StatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _legalNameController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _currencyController = TextEditingController();
  final _trnController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _brandColorController = TextEditingController();
  
  int _startMonth = 1;
  bool _isLoading = false;

  final _companyService = CompanyService();

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void dispose() {
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _countryController.dispose();
    _currencyController.dispose();
    _trnController.dispose();
    _logoUrlController.dispose();
    _brandColorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _companyService.setupCompany(
          uid: user.uid,
          companyLegalName: _legalNameController.text.trim(),
          tradeName: _tradeNameController.text.trim(),
          country: _countryController.text.trim(),
          currency: _currencyController.text.trim(),
          trnVatNumber: _trnController.text.trim().isEmpty ? null : _trnController.text.trim(),
          financialYearStartMonth: _startMonth,
          companyLogoUrl: _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
          primaryBrandColor: _brandColorController.text.trim().isEmpty ? null : _brandColorController.text.trim(),
        );
        // After success, AuthGate stream will detect user update and navigate to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup Failed: ${e.toString()}'),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Company Setup'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.business_rounded, size: 40, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome to LedGix ERP',
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Let\'s set up your company profile to get started.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 48),
                      
                      // Legal and Trade Names
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _legalNameController,
                              label: 'Company Legal Name',
                              icon: Icons.gavel_rounded,
                              validator: (v) => v!.isEmpty ? 'Please enter legal name' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _tradeNameController,
                              label: 'Trade Name (DBA)',
                              icon: Icons.storefront_rounded,
                              validator: (v) => v!.isEmpty ? 'Please enter trade name' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Country and Currency
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _countryController,
                              label: 'Country',
                              icon: Icons.public_rounded,
                              validator: (v) => v!.isEmpty ? 'Please enter country' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _currencyController,
                              label: 'Base Currency (e.g. USD, AED)',
                              icon: Icons.currency_exchange_rounded,
                              validator: (v) => v!.isEmpty ? 'Please enter currency' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // VAT and Financial Year
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _trnController,
                              label: 'TRN / VAT Number (Optional)',
                              icon: Icons.receipt_long_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _startMonth,
                              decoration: const InputDecoration(
                                labelText: 'Financial Year Start Month',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_month_rounded),
                              ),
                              items: List.generate(12, (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(_months[index]),
                              )),
                              onChanged: (val) => setState(() => _startMonth = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Branding
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _logoUrlController,
                              label: 'Company Logo URL (Optional)',
                              icon: Icons.image_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _brandColorController,
                              label: 'Primary Brand Color (Hex)',
                              icon: Icons.palette_rounded,
                              hintText: '#4A90E2',
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                              )
                            : const Text(
                                'CREATE COMPANY & INITIALIZE ERP',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
