import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:ledgixerp/core/widgets/erp_layout.dart';
import 'package:ledgixerp/core/widgets/erp_data_table.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/features/crm/customers/presentation/widgets/customer_pane.dart';
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
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageCustomers,
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ERPPageHeader(
            title: 'Customers',
            subtitle: 'Manage and track your customer base',
            actions: [
              if (canManage) ...[
                OutlinedButton.icon(
                  onPressed: () => _showImportModal(context),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('Import'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showExportModal(context),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Export'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showCustomerPane(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                ),
              ],
            ],
          ),
          ERPActionToolbar(
            searchField: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CustomerModel>>(
              stream: _customerService.getCustomers(widget.user.companyId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = snapshot.data ?? [];

                if (customers.isEmpty) {
                  return ERPEmptyState(
                    title: 'No customers found',
                    message: 'Get started by adding your first customer',
                    icon: Icons.people_outline,
                    action: canManage
                        ? ElevatedButton.icon(
                            onPressed: () => _showCustomerPane(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Your First Customer'),
                          )
                        : null,
                  );
                }

                return ERPDataTable<CustomerModel>(
                  columns: const ['NAME', 'EMAIL', 'PHONE', 'STATUS', ''],
                  items: customers,
                  rowBuilder: (customer, index) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(customer.email)),
                        DataCell(Text(customer.phone ?? '-')),
                        DataCell(
                          ERPStatusBadge.fromStatus(
                            customer.isActive ? 'Active' : 'Inactive',
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: canManage ? () => _showCustomerPane(context, customer: customer) : null,
                                visualDensity: VisualDensity.compact,
                              ),
                              if (canManage)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _confirmDelete(customer),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ),
                      ],
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


  Future<void> _confirmDelete(CustomerModel customer) async {
    showDialog(
      context: context,
      builder: (_) => ERPConfirmDeleteDialog(
        title: 'Delete Customer',
        message: 'Are you sure you want to delete customer ${customer.name}? This action cannot be undone.',
        onConfirm: () async {
          try {
            await _customerService.deleteCustomer(widget.user.companyId!, customer.id);
          } catch (e) {
            if (mounted) showErpError(context: context, error: e);
          }
        },
      ),
    );
  }

  void _showCustomerPane(BuildContext context, {CustomerModel? customer}) {
    showErpSidePane(
      context: context,
      builder: CustomerPane(
        companyId: widget.user.companyId!,
        customer: customer,
      ),
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
