import 'package:flutter/material.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';

import 'package:ledgixerp/widgets/erp_ui_components.dart';

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
            ? 'no-email@temporary.com' // Fallback for model if email is required
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
    return ErpGlassModal(
      title: 'Add New Customer',
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      isLoading: _isLoading,
      saveLabel: 'Save Customer',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              style: ErpFormStyle.inputStyle(context),
              decoration: ErpFormStyle.inputDecoration(context, 'Customer/Company Name', icon: Icons.person),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              style: ErpFormStyle.inputStyle(context),
              decoration: ErpFormStyle.inputDecoration(context, 'Email Address (Optional)', icon: Icons.email),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Invalid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Phone Number', icon: Icons.phone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _taxController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Tax Number (VAT/TRN)', icon: Icons.description),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              style: ErpFormStyle.inputStyle(context),
              decoration: ErpFormStyle.inputDecoration(context, 'Billing Address', icon: Icons.location_on),
            ),
          ],
        ),
      ),
    );
  }
}
