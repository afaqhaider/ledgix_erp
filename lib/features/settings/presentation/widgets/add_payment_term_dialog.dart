import 'package:flutter/material.dart';
import '../../models/payment_term_model.dart';
import '../../services/terms_service.dart';

class AddPaymentTermDialog extends StatefulWidget {
  final String companyId;
  const AddPaymentTermDialog({super.key, required this.companyId});

  @override
  State<AddPaymentTermDialog> createState() => _AddPaymentTermDialogState();
}

class _AddPaymentTermDialogState extends State<AddPaymentTermDialog> {
  final _formKey = GlobalKey<FormState>();
  final _termsService = TermsService();

  String _name = '';
  int _days = 0;
  bool _isDefault = false;
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final term = PaymentTermModel(
        id: '',
        companyId: widget.companyId,
        name: _name,
        days: _days,
        isDefault: _isDefault,
      );
      await _termsService.addPaymentTerm(term);
      if (mounted) Navigator.pop(context);
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
    return AlertDialog(
      title: const Text('Add Payment Term (Quotation Validity)'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Term Name (e.g., Valid for 15 Days)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Number of Days',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => _days = int.tryParse(v ?? '0') ?? 0,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set as Default'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
