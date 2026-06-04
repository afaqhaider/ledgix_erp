import 'package:flutter/material.dart';
import '../../models/credit_term_model.dart';
import '../../services/terms_service.dart';

class AddCreditTermDialog extends StatefulWidget {
  final String companyId;
  const AddCreditTermDialog({super.key, required this.companyId});

  @override
  State<AddCreditTermDialog> createState() => _AddCreditTermDialogState();
}

class _AddCreditTermDialogState extends State<AddCreditTermDialog> {
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
      final term = CreditTermModel(
        id: '',
        companyId: widget.companyId,
        name: _name,
        days: _days,
        isDefault: _isDefault,
      );
      await _termsService.addCreditTerm(term);
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
      title: const Text('Add Credit Term'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Term Name (e.g., Net 30)',
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
