import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../models/company_model.dart';
import '../../services/company_service.dart';

class CompanySetupScreen extends StatefulWidget {
  final AppUser user;
  const CompanySetupScreen({super.key, required this.user});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyService = CompanyService();

  int _currentStep = 0;
  bool _isLoading = false;

  // Form Controllers
  final _legalNameController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');
  final _trnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _timezoneController = TextEditingController(text: 'UTC');

  int _financialYearStartMonth = 1;
  Color _primaryColor = const Color(0xFF0F172A);
  Color _secondaryColor = const Color(0xFF3B82F6);

  XFile? _logoFile;
  Uint8List? _logoBytes;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _logoFile = image;
          _logoBytes = bytes;
        });
      } else {
        setState(() {
          _logoFile = image;
        });
      }
    }
  }

  Future<void> _setupCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final company = CompanyModel(
        id: '',
        companyLegalName: _legalNameController.text.trim(),
        tradeName: _tradeNameController.text.trim(),
        primaryBrandColor:
            '0x${_primaryColor.toARGB32().toRadixString(16).toUpperCase()}',
        secondaryBrandColor:
            '0x${_secondaryColor.toARGB32().toRadixString(16).toUpperCase()}',
        country: _countryController.text.trim(),
        baseCurrency: _currencyController.text.trim(),
        trnVatNumber: _trnController.text.trim().isEmpty
            ? null
            : _trnController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        financialYearStartMonth: _financialYearStartMonth,
        timezone: _timezoneController.text.trim(),
        createdAt: DateTime.now(),
        createdByUserId: widget.user.uid,
      );

      final companyId = await _companyService.setupCompany(company);

      if (_logoFile != null) {
        final uploadedUrl = await _companyService.uploadLogo(
          companyId,
          kIsWeb ? _logoBytes : File(_logoFile!.path),
        );
        if (uploadedUrl != null) {
          await _companyService.updateCompany(
            company.copyWith(companyLogoUrl: uploadedUrl).copyWithId(companyId),
          );
        }
      }

      // AuthGate will naturally pick up the change and redirect
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          margin: const EdgeInsets.symmetric(vertical: 40),
          child: Card(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(theme),
                  Expanded(
                    child: Stepper(
                      type: StepperType.horizontal,
                      currentStep: _currentStep,
                      onStepContinue: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _setupCompany();
                        }
                      },
                      onStepCancel: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                        }
                      },
                      steps: [
                        Step(
                          title: const Text('Basic Info'),
                          isActive: _currentStep >= 0,
                          content: _buildBasicInfo(theme),
                        ),
                        Step(
                          title: const Text('Branding'),
                          isActive: _currentStep >= 1,
                          content: _buildBranding(theme),
                        ),
                        Step(
                          title: const Text('Financial'),
                          isActive: _currentStep >= 2,
                          content: _buildFinancial(theme),
                        ),
                      ],
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            children: [
                              if (_currentStep > 0)
                                OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Back'),
                                ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _currentStep == 2
                                            ? 'Complete Setup'
                                            : 'Next',
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.business_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            'Setup Your Company',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your business to get started with LedGix ERP.',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _legalNameController,
                decoration: const InputDecoration(
                  labelText: 'Company Legal Name*',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _tradeNameController,
                decoration: const InputDecoration(
                  labelText: 'Trade Name*',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country*',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildBranding(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Logo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _logoFile != null
                    ? kIsWeb
                          ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                          : Image.file(
                              File(_logoFile!.path),
                              fit: BoxFit.contain,
                            )
                    : const Icon(
                        Icons.add_a_photo_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Logo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Brand Colors',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Primary Color'),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: () => _showColorPicker(true),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('Secondary Color'),
                trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onTap: () => _showColorPicker(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancial(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(
                  labelText: 'Base Currency*',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _trnController,
                decoration: const InputDecoration(
                  labelText: 'TRN / VAT Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _financialYearStartMonth,
          decoration: const InputDecoration(
            labelText: 'Financial Year Starts*',
            border: OutlineInputBorder(),
          ),
          items: List.generate(12, (index) {
            final month = index + 1;
            return DropdownMenuItem(
              value: month,
              child: Text(_getMonthName(month)),
            );
          }),
          onChanged: (v) => setState(() => _financialYearStartMonth = v!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _timezoneController,
          decoration: const InputDecoration(
            labelText: 'Timezone*',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  void _showColorPicker(bool isPrimary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: isPrimary ? _primaryColor : _secondaryColor,
            onColorChanged: (color) {
              setState(() {
                if (isPrimary) {
                  _primaryColor = color;
                } else {
                  _secondaryColor = color;
                }
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

extension on Widget {
  Widget maxWidth(double width) => Center(
    child: Container(
      constraints: BoxConstraints(maxWidth: width),
      child: this,
    ),
  );
}
