import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';
import 'package:ledgixerp/core/theme/app_spacing.dart';
import 'package:ledgixerp/core/theme/app_text_styles.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/features/crm/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/import_export_modal.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/export_modal.dart';
import 'package:ledgixerp/features/data_migration/models/migration_models.dart';

class CustomersScreen extends StatefulWidget {
  final AppUser user;
  const CustomersScreen({super.key, required this.user});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _customerService = CustomerService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageCustomers,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Customers', style: AppTextStyles.h2),
        actions: [
          if (canManage) ...[
            _buildActionButton(
              onPressed: () => _showImportModal(context),
              icon: Icons.file_upload_outlined,
              label: 'Import',
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              onPressed: () => _showExportModal(context),
              icon: Icons.file_download_outlined,
              label: 'Export',
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddCustomerDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add New'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 0,
              ),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<CustomerModel>>(
        stream: _customerService.getCustomers(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return _buildEmptyState(canManage);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFiltersArea(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadius,
                      ),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('NAME')),
                          DataColumn(label: Text('EMAIL')),
                          DataColumn(label: Text('PHONE')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('')),
                        ],
                        rows: customers.map((customer) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(Text(customer.email)),
                              DataCell(Text(customer.phone ?? '-')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: customer.isActive
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    customer.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: customer.isActive
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      onPressed: canManage ? () {} : null,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (canManage)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _confirmDelete(customer),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildFiltersArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey[100]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterChip('All Status'),
          const SizedBox(width: 8),
          _buildFilterChip('Date Added'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 14),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool canManage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (canManage) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddCustomerDialog(context),
              child: const Text('Add Your First Customer'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(CustomerModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete customer ${customer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _customerService.deleteCustomer(
        widget.user.companyId!,
        customer.id,
      );
    }
  }

  void _showAddCustomerDialog(BuildContext context) {
    SidePanel.show(
      context: context,
      title: 'Add New Customer',
      child: AddCustomerDialog(companyId: widget.user.companyId!),
    );
  }

  void _showImportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImportExportModal(
        initialModule: MigrationModule.customers,
        companyId: widget.user.companyId!,
      ),
    );
  }

  void _showExportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          const ExportModal(initialModule: MigrationModule.customers),
    );
  }
}
