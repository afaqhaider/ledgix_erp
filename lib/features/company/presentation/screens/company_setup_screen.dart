import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
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
  bool _showAllCurrencies = false;

  static const List<String> _commonCurrencies = [
    'AED',
    'USD',
    'SAR',
    'PKR',
    'EUR',
    'GBP',
    'INR',
    'BDT',
  ];
  static const List<String> _allCurrencies = [
    'AED',
    'AFN',
    'ALL',
    'AMD',
    'ANG',
    'AOA',
    'ARS',
    'AUD',
    'AWG',
    'AZN',
    'BAM',
    'BBD',
    'BDT',
    'BGN',
    'BHD',
    'BIF',
    'BMD',
    'BND',
    'BOB',
    'BRL',
    'BSD',
    'BTN',
    'BWP',
    'BYN',
    'BZD',
    'CAD',
    'CDF',
    'CHF',
    'CLP',
    'CNY',
    'COP',
    'CRC',
    'CUP',
    'CVE',
    'CZK',
    'DJF',
    'DKK',
    'DOP',
    'DZD',
    'EGP',
    'ERN',
    'ETB',
    'EUR',
    'FJD',
    'FKP',
    'GBP',
    'GEL',
    'GHS',
    'GIP',
    'GMD',
    'GNF',
    'GTQ',
    'GYD',
    'HKD',
    'HNL',
    'HRK',
    'HTG',
    'HUF',
    'IDR',
    'ILS',
    'INR',
    'IQD',
    'IRR',
    'ISK',
    'JMD',
    'JOD',
    'JPY',
    'KES',
    'KGS',
    'KHR',
    'KMF',
    'KPW',
    'KRW',
    'KWD',
    'KYD',
    'KZT',
    'LAK',
    'LBP',
    'LKR',
    'LRD',
    'LSL',
    'LYD',
    'MAD',
    'MDL',
    'MGA',
    'MKD',
    'MMK',
    'MNT',
    'MOP',
    'MRU',
    'MUR',
    'MVR',
    'MWK',
    'MXN',
    'MYR',
    'MZN',
    'NAD',
    'NGN',
    'NIO',
    'NOK',
    'NPR',
    'NZD',
    'OMR',
    'PAB',
    'PEN',
    'PGK',
    'PHP',
    'PKR',
    'PLN',
    'PYG',
    'QAR',
    'RON',
    'RSD',
    'RUB',
    'RWF',
    'SAR',
    'SBD',
    'SCR',
    'SDG',
    'SEK',
    'SGD',
    'SHP',
    'SLL',
    'SOS',
    'SRD',
    'SSP',
    'STN',
    'SYP',
    'SZL',
    'THB',
    'TJS',
    'TMT',
    'TND',
    'TOP',
    'TRY',
    'TTD',
    'TWD',
    'TZS',
    'UAH',
    'UGX',
    'USD',
    'UYU',
    'UZS',
    'VES',
    'VND',
    'VUV',
    'WST',
    'XAF',
    'XCD',
    'XOF',
    'XPF',
    'YER',
    'ZAR',
    'ZMW',
    'ZWL',
  ];

  static const List<String> _timezones = [
    'UTC',
    'Africa/Cairo',
    'Africa/Johannesburg',
    'Africa/Lagos',
    'Africa/Nairobi',
    'America/Anchorage',
    'America/Argentina/Buenos_Aires',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Mexico_City',
    'America/New_York',
    'America/Sao_Paulo',
    'Asia/Bangkok',
    'Asia/Dubai',
    'Asia/Hong_Kong',
    'Asia/Istanbul',
    'Asia/Jakarta',
    'Asia/Karachi',
    'Asia/Kolkata',
    'Asia/Manila',
    'Asia/Riyadh',
    'Asia/Seoul',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Australia/Sydney',
    'Europe/Berlin',
    'Europe/London',
    'Europe/Madrid',
    'Europe/Paris',
    'Europe/Rome',
    'Pacific/Auckland',
  ];

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
    debugPrint('CompanySetup: Starting setup...');
    if (!_formKey.currentState!.validate()) {
      debugPrint('CompanySetup: Validation failed');
      return;
    }

    setState(() => _isLoading = true);
    try {
      debugPrint('CompanySetup: Creating company model...');
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

      debugPrint('CompanySetup: Calling service.setupCompany...');
      final companyId = await _companyService.setupCompany(company);
      debugPrint('CompanySetup: Company created with ID: $companyId');

      if (_logoFile != null) {
        debugPrint('CompanySetup: Uploading logo...');
        final uploadedUrl = await _companyService.uploadLogo(
          companyId,
          kIsWeb ? _logoBytes : File(_logoFile!.path),
          fileName: _logoFile!.name,
          contentType: _logoFile!.mimeType,
        );
        debugPrint('CompanySetup: Updating company with logo URL...');
        await _companyService.updateCompany(
          company.copyWith(companyLogoUrl: uploadedUrl).copyWithId(companyId),
        );
      }

      debugPrint(
        'CompanySetup: Setup complete. Waiting for AuthGate redirect.',
      );
    } catch (e) {
      debugPrint('CompanySetup: ERROR during setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
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
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton.icon(
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
          ),
          Column(
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
              child: DropdownButtonFormField<String>(
                initialValue:
                    (_showAllCurrencies ? _allCurrencies : _commonCurrencies)
                        .contains(_currencyController.text)
                    ? _currencyController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Base Currency*',
                  border: OutlineInputBorder(),
                ),
                items: [
                  ...(_showAllCurrencies ? _allCurrencies : _commonCurrencies)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  if (!_showAllCurrencies)
                    const DropdownMenuItem(
                      value: 'other',
                      child: Text('Other...'),
                    ),
                ],
                onChanged: (v) {
                  if (v == 'other') {
                    setState(() => _showAllCurrencies = true);
                  } else if (v != null) {
                    setState(() => _currencyController.text = v);
                  }
                },
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
        DropdownButtonFormField<String>(
          initialValue: _timezones.contains(_timezoneController.text)
              ? _timezoneController.text
              : 'UTC',
          decoration: const InputDecoration(
            labelText: 'Timezone*',
            border: OutlineInputBorder(),
          ),
          items: _timezones
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _timezoneController.text = v);
          },
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
