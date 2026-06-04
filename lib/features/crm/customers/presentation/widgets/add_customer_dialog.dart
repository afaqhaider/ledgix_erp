import 'package:flutter/material.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';

class AddCustomerDialog extends StatefulWidget {
  final String companyId;

  const AddCustomerDialog({super.key, required this.companyId});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxController = TextEditingController();
  bool _isLoading = false;

  final _customerService = CustomerService();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final customer = CustomerModel(
        id: '',
        companyId: widget.companyId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? ''
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        taxNumber: _taxController.text.trim().isEmpty
            ? null
            : _taxController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _customerService.addCustomer(customer);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Customer / Company Name *'),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 14),
            decoration: _getInputDecoration('e.g. Acme Corp'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Email Address'),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _getInputDecoration('email@example.com'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (!RegExp(
                          r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(v)) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Phone Number'),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _getInputDecoration('+1 234 567 890'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Tax Number (VAT/TRN)'),
          TextFormField(
            controller: _taxController,
            style: const TextStyle(fontSize: 14),
            decoration: _getInputDecoration('Optional'),
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Billing Address'),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: _getInputDecoration('Full street address...'),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Customer',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
