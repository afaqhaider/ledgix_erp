import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../models/company_model.dart';
import '../../services/company_service.dart';

class CompanySettingsScreen extends StatefulWidget {
  final AppUser user;
  const CompanySettingsScreen({super.key, required this.user});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyService = CompanyService();
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _showAllCurrencies = false;
  String? _errorMessage;
  CompanyModel? _company;

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
  final _currencyController = TextEditingController();
  final _trnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _timezoneController = TextEditingController();

  int _financialYearStartMonth = 1;
  Color _primaryColor = const Color(0xFF0F172A);
  Color _secondaryColor = const Color(0xFF3B82F6);

  XFile? _newLogoFile;
  Uint8List? _newLogoBytes;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  void _loadCompany() async {
    if (widget.user.companyId == null) {
      setState(() {
        _isInitialLoading = false;
        _errorMessage = 'No company linked to this user.';
      });
      return;
    }

    try {
      final company = await _companyService
          .getCompany(widget.user.companyId!)
          .first;

      if (!mounted) return;

      if (company != null) {
        setState(() {
          _company = company;
          _legalNameController.text = company.companyLegalName;
          _tradeNameController.text = company.tradeName;
          _countryController.text = company.country;
          _currencyController.text = company.baseCurrency;

          // Auto-expand currencies if the current one is not in the common list
          if (!_commonCurrencies.contains(company.baseCurrency)) {
            _showAllCurrencies = true;
          }

          _trnController.text = company.trnVatNumber ?? '';
          _phoneController.text = company.phone ?? '';
          _emailController.text = company.email ?? '';
          _websiteController.text = company.website ?? '';
          _addressController.text = company.address ?? '';
          _timezoneController.text = company.timezone;
          _financialYearStartMonth = company.financialYearStartMonth;
          _primaryColor = _parseColor(
            company.primaryBrandColor,
            const Color(0xFF0F172A),
          );
          _secondaryColor = _parseColor(
            company.secondaryBrandColor,
            const Color(0xFF3B82F6),
          );
          _isInitialLoading = false;
        });
      } else {
        setState(() {
          _isInitialLoading = false;
          _errorMessage = 'Company settings not found.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _errorMessage = 'Error loading company: $e';
        });
      }
    }
  }

  Color _parseColor(String colorStr, Color fallback) {
    try {
      if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr));
      }
      return Color(int.parse('0x$colorStr'));
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newLogoFile = image;
          _newLogoBytes = bytes;
        });
      } else {
        setState(() {
          _newLogoFile = image;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _company == null) return;

    setState(() => _isLoading = true);
    try {
      String? logoUrl = _company!.companyLogoUrl;

      if (_newLogoFile != null) {
        final uploadedUrl = await _companyService.uploadLogo(
          _company!.id,
          kIsWeb ? _newLogoBytes : File(_newLogoFile!.path),
        );
        if (uploadedUrl != null) logoUrl = uploadedUrl;
      }

      final updatedCompany = _company!.copyWith(
        companyLegalName: _legalNameController.text.trim(),
        tradeName: _tradeNameController.text.trim(),
        companyLogoUrl: logoUrl,
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
      );

      await _companyService.updateCompany(updatedCompany);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
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

    if (_isInitialLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCompany,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_company == null) {
      return const Scaffold(
        body: Center(child: Text('Company data unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                theme,
                'Basic Information',
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Legal Name',
                            _legalNameController,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'Trade Name',
                            _tradeNameController,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Country',
                            _countryController,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            'TRN / VAT Number',
                            _trnController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                theme,
                'Contact Details',
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Phone', _phoneController),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('Email', _emailController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Website', _websiteController),
                    const SizedBox(height: 16),
                    _buildTextField('Address', _addressController, maxLines: 2),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                theme,
                'Branding',
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _newLogoFile != null
                              ? (kIsWeb
                                    ? Image.memory(
                                        _newLogoBytes!,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.file(
                                        File(_newLogoFile!.path),
                                        fit: BoxFit.contain,
                                      ))
                              : (_company!.companyLogoUrl != null
                                    ? Image.network(
                                        _company!.companyLogoUrl!,
                                        fit: BoxFit.contain,
                                      )
                                    : const Icon(Icons.business, size: 48)),
                        ),
                        TextButton(
                          onPressed: _pickLogo,
                          child: const Text('Change Logo'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Primary Brand Color'),
                            trailing: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onTap: () => _showColorPicker(true),
                          ),
                          ListTile(
                            title: const Text('Secondary Brand Color'),
                            trailing: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _secondaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onTap: () => _showColorPicker(false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                theme,
                'Financial & Localization',
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                (_showAllCurrencies
                                        ? _allCurrencies
                                        : _commonCurrencies)
                                    .contains(_currencyController.text)
                                ? _currencyController.text
                                : (_allCurrencies.contains(
                                        _currencyController.text,
                                      )
                                      ? _currencyController.text
                                      : null),
                            decoration: const InputDecoration(
                              labelText: 'Base Currency*',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              ...(_showAllCurrencies
                                      ? _allCurrencies
                                      : _commonCurrencies)
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  ),
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
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _financialYearStartMonth,
                            decoration: const InputDecoration(
                              labelText: 'Financial Year Starts',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(_getMonthName(index + 1)),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _financialYearStartMonth = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue:
                          _timezones.contains(_timezoneController.text)
                          ? _timezoneController.text
                          : 'UTC',
                      decoration: const InputDecoration(
                        labelText: 'Timezone*',
                        border: OutlineInputBorder(),
                      ),
                      items: _timezones
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _timezoneController.text = v);
                        }
                      },
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
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
