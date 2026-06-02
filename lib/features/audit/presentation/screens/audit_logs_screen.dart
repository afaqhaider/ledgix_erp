import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/audit/audit_log_model.dart';
import 'package:ledgixerp/core/audit/audit_service.dart';

class AuditLogsScreen extends StatefulWidget {
  final AppUser user;
  const AuditLogsScreen({super.key, required this.user});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _auditService = AuditService();
  String? _selectedModule;
  String? _selectedAction;

  final List<String> _modules = [
    'customers',
    'suppliers',
    'invoices',
    'quotations',
    'payments',
    'journalEntries',
    'chartOfAccounts',
    'approvals',
    'settings',
  ];

  final List<String> _actions = [
    'create',
    'edit',
    'delete',
    'approve',
    'reject',
    'post',
    'login',
    'logout',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.user.role.name != 'Admin' && widget.user.role.name != 'Owner') {
      return const Center(
        child: Text('Access Denied: Only Admins/Owners can view audit logs.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedModule,
                    decoration: const InputDecoration(
                      labelText: 'Module',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Modules'),
                      ),
                      ..._modules.map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedModule = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAction,
                    decoration: const InputDecoration(
                      labelText: 'Action',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Actions'),
                      ),
                      ..._actions.map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedAction = v),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AuditLogModel>>(
              stream: _auditService.getLogs(
                widget.user.companyId!,
                module: _selectedModule,
                actionType: _selectedAction,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return const Center(child: Text('No audit logs found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getActionColor(
                          log.actionType,
                        ).withValues(alpha: 0.1),
                        child: Icon(
                          _getActionIcon(log.actionType),
                          color: _getActionColor(log.actionType),
                          size: 20,
                        ),
                      ),
                      title: Text(log.description),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'By ${log.userName} in ${log.module.toUpperCase()}',
                          ),
                          if (log.documentNumber != null)
                            Text(
                              'Doc: ${log.documentNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(log.createdAt),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showLogDetails(log),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(AuditLogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('User', log.userName),
              _detailRow('Module', log.module.toUpperCase()),
              _detailRow('Action', log.actionType.toUpperCase()),
              _detailRow('Document', log.documentNumber ?? 'N/A'),
              _detailRow(
                'Time',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt),
              ),
              if (log.deviceInfo != null) _detailRow('Device', log.deviceInfo!),
              const SizedBox(height: 16),
              const Text(
                'Changes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              if (log.oldValues != null) ...[
                const Text(
                  'From:',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                Text(
                  log.oldValues.toString(),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 8),
              ],
              if (log.newValues != null) ...[
                const Text(
                  'To:',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
                Text(
                  log.newValues.toString(),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'edit':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'approve':
        return Colors.teal;
      case 'reject':
        return Colors.orange;
      case 'post':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_outline;
      case 'edit':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'approve':
        return Icons.check_circle_outline;
      case 'reject':
        return Icons.block;
      case 'post':
        return Icons.account_balance;
      default:
        return Icons.history;
    }
  }
}
