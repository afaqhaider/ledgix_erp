import 'package:flutter/material.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class CustomerPane extends StatefulWidget {
  final String companyId;
  final CustomerModel? customer;
  final Function(CustomerModel)? onSuccess;

  const CustomerPane({
    super.key,
    required this.companyId,
    this.customer,
    this.onSuccess,
  });

  @override
  State<CustomerPane> createState() => _CustomerPaneState();
}

class _CustomerPaneState extends State<CustomerPane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _taxController;
  bool _isActive = true;
  bool _isLoading = false;

  final _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _emailController = TextEditingController(text: widget.customer?.email);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _addressController = TextEditingController(text: widget.customer?.address);
    _taxController = TextEditingController(text: widget.customer?.taxNumber);
    _isActive = widget.customer?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final customer = CustomerModel(
        id: widget.customer?.id ?? '',
        companyId: widget.companyId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        taxNumber: _taxController.text.trim().isEmpty ? null : _taxController.text.trim(),
        isActive: _isActive,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
      );

      if (widget.customer == null) {
        await _customerService.addCustomer(customer);
      } else {
        await _customerService.updateCustomer(customer);
      }
      
      if (widget.onSuccess != null) widget.onSuccess!(customer);

      if (mounted) {
        Navigator.pop(context);
        showErpSuccess(
          context: context,
          title: 'Success',
          message: 'Customer ${widget.customer == null ? 'added' : 'updated'} successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        showErpError(context: context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErpSidePane(
      title: widget.customer == null ? 'Add New Customer' : 'Edit Customer',
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      saveLabel: widget.customer == null ? 'Create Customer' : 'Save Changes',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: ErpFormStyle.sectionHeaderStyle(context),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: ErpFormStyle.inputDecoration(
                context,
                'Customer / Company Name *',
                icon: Icons.business,
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Email Address',
                      icon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: ErpFormStyle.inputDecoration(
                      context,
                      'Phone Number',
                      icon: Icons.phone_outlined,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Tax & Address',
              style: ErpFormStyle.sectionHeaderStyle(context),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxController,
              decoration: ErpFormStyle.inputDecoration(
                context,
                'Tax Number (VAT/TRN)',
                icon: Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: ErpFormStyle.inputDecoration(
                context,
                'Billing Address',
                icon: Icons.location_on_outlined,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            SwitchListTile(
              title: const Text('Active Status', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Inactive customers cannot be used in new transactions', style: TextStyle(fontSize: 12)),
              value: _isActive,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
