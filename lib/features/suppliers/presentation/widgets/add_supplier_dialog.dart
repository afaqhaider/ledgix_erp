import 'package:flutter/material.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';
import 'package:ledgixerp/features/suppliers/services/supplier_service.dart';

import 'package:ledgixerp/widgets/erp_ui_components.dart';

class AddSupplierDialog extends StatefulWidget {
  final String companyId;

  const AddSupplierDialog({super.key, required this.companyId});

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _trnController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');

  BalanceType _balanceType = BalanceType.credit;
  bool _isLoading = false;
  String _generatedCode = 'Loading...';

  final _supplierService = SupplierService();

  @override
  void initState() {
    super.initState();
    _loadNextCode();
  }

  Future<void> _loadNextCode() async {
    final code = await _supplierService.generateNextSupplierCode(
      widget.companyId,
    );
    if (mounted) {
      setState(() => _generatedCode = code);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final supplier = SupplierModel(
        id: '',
        companyId: widget.companyId,
        supplierCode: _generatedCode,
        supplierName: _nameController.text.trim(),
        contactPerson: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? 'no-email@temporary.com'
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        trnVatNumber: _trnController.text.trim().isEmpty
            ? null
            : _trnController.text.trim(),
        openingBalance: double.tryParse(_balanceController.text) ?? 0.0,
        openingBalanceType: _balanceType,
        createdAt: DateTime.now(),
      );

      await _supplierService.addSupplier(supplier);
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
      title: 'Add New Supplier',
      width: 700,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      isLoading: _isLoading,
      saveLabel: 'Save Supplier',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: ErpFormStyle.inputDecoration(context, 'Supplier Code'),
                    child: Text(_generatedCode, style: ErpFormStyle.inputStyle(context)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Supplier/Company Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contactController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Contact Person'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Email Address'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Phone Number'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _trnController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'TRN / VAT Number'),
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
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Country'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _addressController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Address'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Opening Balance', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _balanceController,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Balance Amount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<BalanceType>(
                    value: _balanceType,
                    style: ErpFormStyle.inputStyle(context),
                    decoration: ErpFormStyle.inputDecoration(context, 'Type'),
                    items: BalanceType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _balanceType = val!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
