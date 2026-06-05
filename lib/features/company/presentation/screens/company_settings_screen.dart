import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/widgets/app_logo_image.dart';
import 'package:ledgixerp/widgets/form_layout.dart';
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
  String? _errorMessage;
  CompanyModel? _company;

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
  final _trnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateOrEmirateController = TextEditingController();
  final _poBoxController = TextEditingController();
  final _timezoneController = TextEditingController();

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

          _trnController.text = company.trnVatNumber ?? '';
          _phoneController.text = company.phone ?? '';
          _emailController.text = company.email ?? '';
          _websiteController.text = company.website ?? '';
          _addressLine1Controller.text =
              company.addressLine1 ?? company.address ?? '';
          _addressLine2Controller.text = company.addressLine2 ?? '';
          _cityController.text = company.city ?? '';
          _stateOrEmirateController.text = company.stateOrEmirate ?? '';
          _poBoxController.text = company.poBox ?? '';
          _timezoneController.text = company.timezone;
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
      debugPrint('CompanySettings: Selected logo ${image.name}');
      Uint8List? selectedBytes;
      if (kIsWeb) {
        selectedBytes = await image.readAsBytes();
        setState(() {
          _newLogoFile = image;
          _newLogoBytes = selectedBytes;
        });
      } else {
        setState(() {
          _newLogoFile = image;
        });
      }

      await _saveSelectedLogo(image, selectedBytes);
    }
  }

  Future<void> _saveSelectedLogo(XFile image, Uint8List? selectedBytes) async {
    if (_company == null) return;

    setState(() => _isLoading = true);
    try {
      final logoUrl = await _companyService.uploadLogo(
        _company!.id,
        kIsWeb ? selectedBytes : File(image.path),
        fileName: image.name,
        contentType: image.mimeType,
      );
      final updatedCompany = _company!.copyWith(companyLogoUrl: logoUrl);
      await _companyService.updateCompany(updatedCompany);

      if (mounted) {
        setState(() {
          _company = updatedCompany;
          _newLogoFile = null;
          _newLogoBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating logo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _company == null) return;

    setState(() => _isLoading = true);
    try {
      String? logoUrl = _company!.companyLogoUrl;
      debugPrint(
        'CompanySettings: Saving settings. Existing logo=${logoUrl ?? '(none)'}. New logo selected=${_newLogoFile != null}',
      );

      if (_newLogoFile != null) {
        logoUrl = await _companyService.uploadLogo(
          _company!.id,
          kIsWeb ? _newLogoBytes : File(_newLogoFile!.path),
          fileName: _newLogoFile!.name,
          contentType: _newLogoFile!.mimeType,
        );
        debugPrint('CompanySettings: Uploaded logo path=$logoUrl');
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
        baseCurrency: _company!.baseCurrency,
        trnVatNumber: _trnController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        address: '',
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        stateOrEmirate: _stateOrEmirateController.text.trim(),
        poBox: _poBoxController.text.trim(),
        financialYearStartMonth: _company!.financialYearStartMonth,
        timezone: _timezoneController.text.trim(),
      );

      await _companyService.updateCompany(updatedCompany);
      if (mounted) {
        setState(() {
          _company = updatedCompany;
          _newLogoFile = null;
          _newLogoBytes = null;
        });
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
        title: const Text('Basic Settings'),
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
        padding: const EdgeInsets.all(16),
        child: FormLayout(
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
                              'TRN / VAT Number',
                              _trnController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTimezoneField()),
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  theme,
                  'Address',
                  Column(
                    children: [
                      _buildTextField(
                        'Address Line 1',
                        _addressLine1Controller,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Address Line 2',
                        _addressLine2Controller,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('City', _cityController),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              'State / Emirate',
                              _stateOrEmirateController,
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
                              'P.O. Box',
                              _poBoxController,
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
                                : _buildSavedLogoPreview(theme),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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

  Widget _buildSavedLogoPreview(ThemeData theme) {
    return _buildLogoFallback(theme);
  }

  Widget _buildLogoFallback(ThemeData theme) {
    return const AppLogoImage(
      width: 88,
      height: 88,
      padding: EdgeInsets.all(16),
    );
  }

  Widget _buildTimezoneField() {
    return DropdownButtonFormField<String>(
      initialValue: _timezones.contains(_timezoneController.text)
          ? _timezoneController.text
          : 'UTC',
      decoration: const InputDecoration(
        labelText: 'Timezone*',
        border: OutlineInputBorder(),
      ),
      items: _timezones
          .map(
            (timezone) =>
                DropdownMenuItem(value: timezone, child: Text(timezone)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _timezoneController.text = value);
        }
      },
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
}
