import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/features/approvals/models/approval_rule_model.dart';
import 'package:ledgixerp/features/approvals/services/approval_service.dart';
import 'package:uuid/uuid.dart';

class ApprovalRulesScreen extends StatefulWidget {
  final AppUser user;
  const ApprovalRulesScreen({super.key, required this.user});

  @override
  State<ApprovalRulesScreen> createState() => _ApprovalRulesScreenState();
}

class _ApprovalRulesScreenState extends State<ApprovalRulesScreen> {
  final _approvalService = ApprovalService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Rules'),
        actions: [
          TextButton.icon(
            onPressed: () => _showRuleDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Rule'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<ApprovalRuleModel>>(
        stream: _approvalService.getRules(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rules = snapshot.data ?? [];
          if (rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rule_folder_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No approval rules configured',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showRuleDialog(),
                    child: const Text('Configure First Rule'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _buildRuleCard(rule);
            },
          );
        },
      ),
    );
  }

  Widget _buildRuleCard(ApprovalRuleModel rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          rule.module.name.toUpperCase().replaceAll('_', ' '),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Threshold: ${rule.minAmount.toStringAsFixed(0)} - ${rule.maxAmount == double.infinity ? '∞' : rule.maxAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: rule.requiredApproverRoles
                  .map(
                    (r) => Chip(
                      label: Text(r.name, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        trailing: Switch(
          value: rule.isEnabled,
          onChanged: (val) {
            _approvalService.saveRule(
              ApprovalRuleModel(
                id: rule.id,
                companyId: rule.companyId,
                module: rule.module,
                minAmount: rule.minAmount,
                maxAmount: rule.maxAmount,
                requiredApproverRoles: rule.requiredApproverRoles,
                isEnabled: val,
              ),
            );
          },
        ),
        onTap: () => _showRuleDialog(rule: rule),
      ),
    );
  }

  void _showRuleDialog({ApprovalRuleModel? rule}) {
    showDialog(
      context: context,
      builder: (context) => _RuleDialog(
        companyId: widget.user.companyId!,
        rule: rule,
        onSave: (newRule) {
          _approvalService.saveRule(newRule);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _RuleDialog extends StatefulWidget {
  final String companyId;
  final ApprovalRuleModel? rule;
  final Function(ApprovalRuleModel) onSave;

  const _RuleDialog({required this.companyId, this.rule, required this.onSave});

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late ApprovalModule _selectedModule;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late List<UserRole> _selectedRoles;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.rule?.module ?? ApprovalModule.salesInvoices;
    _minController = TextEditingController(
      text: widget.rule?.minAmount.toString() ?? '0',
    );
    _maxController = TextEditingController(
      text: widget.rule?.maxAmount == double.infinity
          ? ''
          : widget.rule?.maxAmount.toString() ?? '',
    );
    _selectedRoles = List.from(widget.rule?.requiredApproverRoles ?? []);
    _isEnabled = widget.rule?.isEnabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.rule == null ? 'New Approval Rule' : 'Edit Approval Rule',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<ApprovalModule>(
              initialValue: _selectedModule,
              decoration: const InputDecoration(labelText: 'Module'),
              items: ApprovalModule.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedModule = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    decoration: const InputDecoration(labelText: 'Min Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    decoration: const InputDecoration(
                      labelText: 'Max Amount (Empty for ∞)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Required Approver Roles',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...UserRole.values.map((role) {
              if (role == UserRole.employee) return const SizedBox.shrink();
              return CheckboxListTile(
                title: Text(role.name),
                value: _selectedRoles.contains(role),
                dense: true,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedRoles.add(role);
                    } else {
                      _selectedRoles.remove(role);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final min = double.tryParse(_minController.text) ?? 0;
            final maxText = _maxController.text.trim();
            final max = maxText.isEmpty
                ? double.infinity
                : double.tryParse(maxText) ?? double.infinity;

            final newRule = ApprovalRuleModel(
              id: widget.rule?.id ?? const Uuid().v4(),
              companyId: widget.companyId,
              module: _selectedModule,
              minAmount: min,
              maxAmount: max,
              requiredApproverRoles: _selectedRoles,
              isEnabled: _isEnabled,
            );
            widget.onSave(newRule);
          },
          child: const Text('Save Rule'),
        ),
      ],
    );
  }
}
