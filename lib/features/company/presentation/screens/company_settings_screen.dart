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
  CompanyModel? _company;

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

  void _loadCompany() {
    if (widget.user.companyId == null) return;

    _companyService.getCompany(widget.user.companyId!).first.then((company) {
      if (company != null && mounted) {
        setState(() {
          _company = company;
          _legalNameController.text = company.companyLegalName;
          _tradeNameController.text = company.tradeName;
          _countryController.text = company.country;
          _currencyController.text = company.baseCurrency;
          _trnController.text = company.trnVatNumber ?? '';
          _phoneController.text = company.phone ?? '';
          _emailController.text = company.email ?? '';
          _websiteController.text = company.website ?? '';
          _addressController.text = company.address ?? '';
          _timezoneController.text = company.timezone;
          _financialYearStartMonth = company.financialYearStartMonth;
          _primaryColor = Color(int.parse(company.primaryBrandColor));
          _secondaryColor = Color(int.parse(company.secondaryBrandColor));
        });
      }
    });
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

    if (_company == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                          child: _buildTextField(
                            'Base Currency',
                            _currencyController,
                            isRequired: true,
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
                    _buildTextField(
                      'Timezone',
                      _timezoneController,
                      isRequired: true,
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
