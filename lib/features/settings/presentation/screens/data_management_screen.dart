import 'package:flutter/material.dart';
import '../../../../core/auth/app_user.dart';
import '../../../data_migration/models/migration_models.dart';
import '../../../data_migration/presentation/widgets/import_export_modal.dart';

class DataManagementScreen extends StatelessWidget {
  final AppUser user;
  const DataManagementScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildDataSection(
            context,
            'Customers',
            'Import or export your customer list.',
            Icons.people,
          ),
          const SizedBox(height: 16),
          _buildDataSection(
            context,
            'Suppliers',
            'Import or export your supplier list.',
            Icons.local_shipping,
          ),
          const SizedBox(height: 16),
          _buildDataSection(
            context,
            'Chart of Accounts',
            'Import or export your accounts.',
            Icons.account_tree,
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, String title, String subtitle, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(subtitle),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _handleImport(context, title),
                  icon: const Icon(Icons.upload),
                  label: const Text('Import Excel/CSV'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {}, // TODO: Export logic
                  icon: const Icon(Icons.download),
                  label: const Text('Export XLSX'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleImport(BuildContext context, String title) {
    MigrationModule module;
    switch (title) {
      case 'Customers':
        module = MigrationModule.customers;
        break;
      case 'Suppliers':
        module = MigrationModule.suppliers;
        break;
      case 'Chart of Accounts':
        module = MigrationModule.chartOfAccounts;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => ImportExportModal(initialModule: module),
    );
  }
}
