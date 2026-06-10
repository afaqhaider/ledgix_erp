import 'package:flutter/material.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';
import 'package:ledgixerp/features/suppliers/services/supplier_service.dart';
import 'package:ledgixerp/features/accounting/chart_of_accounts/account_model.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';

class SupplierPane extends StatefulWidget {
  final String companyId;
  final SupplierModel? supplier;
  final Function(SupplierModel)? onSuccess;

  const SupplierPane({
    super.key,
    required this.companyId,
    this.supplier,
    this.onSuccess,
  });

  @override
  State<SupplierPane> createState() => _SupplierPaneState();
}

class _SupplierPaneState extends State<SupplierPane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _contactPersonController;
  late TextEditingController _addressController;
  late TextEditingController _taxController;
  late TextEditingController _openingBalanceController;
  
  BalanceType _openingBalanceType = BalanceType.credit;
  bool _isActive = true;
  bool _isLoading = false;

  final _supplierService = SupplierService();

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.supplier?.supplierCode);
    _nameController = TextEditingController(text: widget.supplier?.supplierName);
    _emailController = TextEditingController(text: widget.supplier?.email);
    _phoneController = TextEditingController(text: widget.supplier?.phone);
    _contactPersonController = TextEditingController(text: widget.supplier?.contactPerson);
    _addressController = TextEditingController(text: widget.supplier?.address);
    _taxController = TextEditingController(text: widget.supplier?.trnVatNumber);
    _openingBalanceController = TextEditingController(
      text: widget.supplier?.openingBalance.toString() ?? '0.00',
    );
    _openingBalanceType = widget.supplier?.openingBalanceType ?? BalanceType.credit;
    _isActive = widget.supplier?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final supplier = SupplierModel(
        id: widget.supplier?.id ?? '',
        companyId: widget.companyId,
        supplierCode: _codeController.text.trim(),
        supplierName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        trnVatNumber: _taxController.text.trim().isEmpty ? null : _taxController.text.trim(),
        openingBalance: double.tryParse(_openingBalanceController.text) ?? 0,
        openingBalanceType: _openingBalanceType,
        isActive: _isActive,
        createdAt: widget.supplier?.createdAt ?? DateTime.now(),
      );

      if (widget.supplier == null) {
        await _supplierService.addSupplier(supplier);
      } else {
        await _supplierService.updateSupplier(supplier);
      }
      
      if (widget.onSuccess != null) widget.onSuccess!(supplier);

      if (mounted) {
        Navigator.pop(context);
        showErpSuccess(
          context: context,
          title: 'Success',
          message: 'Supplier ${widget.supplier == null ? 'added' : 'updated'} successfully.',
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
      title: widget.supplier == null ? 'Add New Supplier' : 'Edit Supplier',
      isLoading: _isLoading,
      onCancel: () => Navigator.pop(context),
      onSave: _save,
      saveLabel: widget.supplier == null ? 'Create Supplier' : 'Save Changes',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Supplier Code *', icon: Icons.qr_code),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Supplier Name *', icon: Icons.business),
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
                    controller: _emailController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Email Address', icon: Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Phone Number', icon: Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPersonController,
              decoration: ErpFormStyle.inputDecoration(context, 'Contact Person', icon: Icons.person_outline),
            ),
            
            const SizedBox(height: 24),
            Text('Opening Balance', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _openingBalanceController,
                    decoration: ErpFormStyle.inputDecoration(context, 'Amount', icon: Icons.account_balance_wallet_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: widget.supplier == null, // Opening balance usually only editable during creation
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<BalanceType>(
                    initialValue: _openingBalanceType,
                    items: BalanceType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: widget.supplier == null ? (v) => setState(() => _openingBalanceType = v!) : null,
                    decoration: ErpFormStyle.inputDecoration(context, 'Type'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text('Tax & Address', style: ErpFormStyle.sectionHeaderStyle(context)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxController,
              decoration: ErpFormStyle.inputDecoration(context, 'Tax Number (VAT/TRN)', icon: Icons.receipt_long_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: ErpFormStyle.inputDecoration(context, 'Billing Address', icon: Icons.location_on_outlined),
            ),
            const SizedBox(height: 24),
            const Divider(),
            SwitchListTile(
              title: const Text('Active Status', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Inactive suppliers cannot be used in new transactions', style: TextStyle(fontSize: 12)),
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
