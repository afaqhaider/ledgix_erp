import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. Net 30)',
                ),
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
                if (context.mounted) Navigator.pop(context);
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
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: StreamBuilder<List<CreditTermModel>>(
            stream: _service.getCreditTerms(widget.user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final terms = snapshot.data!;
              if (terms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_off_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No credit terms defined',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: terms.length,
                itemBuilder: (context, index) {
                  final term = terms[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          term.days.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        term.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${term.days} days'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (term.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      onTap: () => _showAddDialog(term),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Credit Terms',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Define payment deadlines for customers and suppliers',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Term'),
          ),
        ],
      ),
    );
  }
}
