import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/widgets/erp_layout.dart';
import 'package:ledgixerp/core/widgets/erp_data_table.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';
import 'package:ledgixerp/features/suppliers/services/supplier_service.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import 'package:ledgixerp/features/suppliers/presentation/widgets/supplier_pane.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/import_export_modal.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/export_modal.dart';
import 'package:ledgixerp/features/data_migration/models/migration_models.dart';

class SuppliersScreen extends StatefulWidget {
  final AppUser user;
  const SuppliersScreen({super.key, required this.user});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _supplierService = SupplierService();

  @override
  Widget build(BuildContext context) {
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageSuppliers,
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          ERPPageHeader(
            title: 'Suppliers',
            subtitle: 'Manage your vendors and procurement contacts',
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
                  onPressed: () => _showSupplierPane(context),
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
                  hintText: 'Search suppliers...',
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
            child: StreamBuilder<List<SupplierModel>>(
              stream: _supplierService.getSuppliers(widget.user.companyId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final suppliers = snapshot.data ?? [];

                if (suppliers.isEmpty) {
                  return ERPEmptyState(
                    title: 'No suppliers found',
                    message: 'Get started by adding your first supplier',
                    icon: Icons.local_shipping_outlined,
                    action: canManage
                        ? ElevatedButton.icon(
                            onPressed: () => _showSupplierPane(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Your First Supplier'),
                          )
                        : null,
                  );
                }

                return ERPDataTable<SupplierModel>(
                  columns: const [
                    'CODE',
                    'SUPPLIER NAME',
                    'CONTACT',
                    'OPENING BALANCE',
                    'STATUS',
                    '',
                  ],
                  items: suppliers,
                  rowBuilder: (supplier, index) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            supplier.supplierCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.supplierName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                supplier.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(supplier.contactPerson ?? '—')),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${AppFormatters.currency(supplier.openingBalance)} ${supplier.openingBalanceType.label.substring(0, 2)}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        DataCell(
                          ERPStatusBadge.fromStatus(
                            supplier.isActive ? 'Active' : 'Inactive',
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: canManage ? () => _showSupplierPane(context, supplier: supplier) : null,
                                visualDensity: VisualDensity.compact,
                              ),
                              if (canManage)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _confirmDelete(supplier),
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


  Future<void> _confirmDelete(SupplierModel supplier) async {
    showDialog(
      context: context,
      builder: (_) => ERPConfirmDeleteDialog(
        title: 'Delete Supplier',
        message: 'Are you sure you want to delete supplier ${supplier.supplierName}? This will only work if there are no linked transactions. This action cannot be undone.',
        onConfirm: () async {
          try {
            await _supplierService.deleteSupplier(widget.user.companyId!, supplier.id);
          } catch (e) {
            if (mounted) showErpError(context: context, error: e);
          }
        },
      ),
    );
  }

  void _showSupplierPane(BuildContext context, {SupplierModel? supplier}) {
    showErpSidePane(
      context: context,
      builder: SupplierPane(
        companyId: widget.user.companyId!,
        supplier: supplier,
      ),
    );
  }

  void _showImportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImportExportModal(
        initialModule: MigrationModule.suppliers,
        companyId: widget.user.companyId!,
      ),
    );
  }

  void _showExportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          const ExportModal(initialModule: MigrationModule.suppliers),
    );
  }
}
