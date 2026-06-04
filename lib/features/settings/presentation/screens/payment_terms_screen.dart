import 'package:flutter/material.dart';
import '../../../../core/auth/app_user.dart';
import '../../models/payment_term_model.dart';
import '../../services/terms_service.dart';

class PaymentTermsScreen extends StatefulWidget {
  final AppUser user;
  const PaymentTermsScreen({super.key, required this.user});

  @override
  State<PaymentTermsScreen> createState() => _PaymentTermsScreenState();
}

class _PaymentTermsScreenState extends State<PaymentTermsScreen> {
  final _service = TermsService();

  void _showAddDialog([PaymentTermModel? term]) {
    final nameController = TextEditingController(text: term?.name);
    final daysController = TextEditingController(text: term?.days.toString());
    bool isDefault = term?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(term == null ? 'Add Payment Term' : 'Edit Payment Term'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: daysController,
                decoration: const InputDecoration(labelText: 'Days'),
                keyboardType: TextInputType.number,
              ),
              CheckboxListTile(
                title: const Text('Default'),
                value: isDefault,
                onChanged: (val) => setDialogState(() => isDefault = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTerm = PaymentTermModel(
                  id: term?.id ?? '',
                  companyId: widget.user.companyId!,
                  name: nameController.text,
                  days: int.tryParse(daysController.text) ?? 0,
                  isDefault: isDefault,
                );
                if (term == null) {
                  await _service.addPaymentTerm(newTerm);
                } else {
                  // TODO: Add updatePaymentTerm to service if needed, for now just add
                  await _service.addPaymentTerm(newTerm);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Terms (Quotations)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<PaymentTermModel>>(
        stream: _service.getPaymentTerms(widget.user.companyId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final terms = snapshot.data!;
          return ListView.builder(
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index];
              return ListTile(
                title: Text(term.name),
                subtitle: Text('${term.days} days'),
                trailing: term.isDefault
                    ? const Chip(label: Text('Default'))
                    : null,
                onTap: () => _showAddDialog(term),
              );
            },
          );
        },
      ),
    );
  }
}
