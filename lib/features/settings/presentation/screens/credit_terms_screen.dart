import 'package:flutter/material.dart';
import '../../../../core/auth/app_user.dart';
import '../../models/credit_term_model.dart';
import '../../services/terms_service.dart';

class CreditTermsScreen extends StatefulWidget {
  final AppUser user;
  const CreditTermsScreen({super.key, required this.user});

  @override
  State<CreditTermsScreen> createState() => _CreditTermsScreenState();
}

class _CreditTermsScreenState extends State<CreditTermsScreen> {
  final _service = TermsService();

  void _showAddDialog([CreditTermModel? term]) {
    final nameController = TextEditingController(text: term?.name);
    final daysController = TextEditingController(text: term?.days.toString());
    bool isDefault = term?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(term == null ? 'Add Credit Term' : 'Edit Credit Term'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name (e.g. Net 30)'),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newTerm = CreditTermModel(
                  id: term?.id ?? '',
                  companyId: widget.user.companyId!,
                  name: nameController.text,
                  days: int.tryParse(daysController.text) ?? 0,
                  isDefault: isDefault,
                );
                if (term == null) {
                  await _service.addCreditTerm(newTerm);
                } else {
                  await _service.updateCreditTerm(newTerm);
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
        title: const Text('Credit Terms'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog()),
        ],
      ),
      body: StreamBuilder<List<CreditTermModel>>(
        stream: _service.getCreditTerms(widget.user.companyId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final terms = snapshot.data!;
          return ListView.builder(
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index];
              return ListTile(
                title: Text(term.name),
                subtitle: Text('${term.days} days'),
                trailing: term.isDefault ? const Chip(label: Text('Default')) : null,
                onTap: () => _showAddDialog(term),
              );
            },
          );
        },
      ),
    );
  }
}
