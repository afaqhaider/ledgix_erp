import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/permission.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';
import 'package:ledgixerp/features/suppliers/services/supplier_service.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:ledgixerp/features/suppliers/presentation/widgets/add_supplier_dialog.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/import_export_modal.dart';
import 'package:ledgixerp/features/data_migration/presentation/widgets/export_modal.dart';
import 'package:ledgixerp/features/data_migration/models/migration_models.dart';

import 'package:google_fonts/google_fonts.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canManage = widget.user.role.hasPermission(
      AppPermission.manageSuppliers,
    );

    return Column(
      children: [
        _buildHeader(theme, canManage),
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
                return _buildEmptyState(theme, canManage);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: DataTable(
                        headingRowHeight: 48,
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 64,
                        horizontalMargin: 24,
                        columnSpacing: 32,
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                        ),
                        columns: [
                          _buildColumn('Code'),
                          _buildColumn('Supplier Name'),
                          _buildColumn('Contact'),
                          _buildColumn('Opening Balance'),
                          _buildColumn('Status'),
                          _buildColumn('Actions'),
                        ],
                        rows: suppliers.map((supplier) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  supplier.supplierCode,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      supplier.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  supplier.contactPerson ?? '—',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${NumberFormat('#,##0.00').format(supplier.openingBalance)} ${supplier.openingBalanceType.label.substring(0, 2)}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (supplier.isActive
                                                ? Colors.green
                                                : Colors.red)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    supplier.isActive ? 'ACTIVE' : 'INACTIVE',
                                    style: TextStyle(
                                      color: supplier.isActive
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                            _confirmDelete(supplier),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool canManage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suppliers',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage your vendors and procurement contacts',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (canManage) ...[
            _buildHeaderAction(
              icon: Icons.south_west_rounded,
              label: 'Import',
              onTap: () => _showImportModal(context),
            ),
            const SizedBox(width: 8),
            _buildHeaderAction(
              icon: Icons.north_east_rounded,
              label: 'Export',
              onTap: () => _showExportModal(context),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddSupplierDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Supplier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  DataColumn _buildColumn(String label, {bool numeric = false}) {
    return DataColumn(
      numeric: numeric,
      label: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool canManage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          if (canManage) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddSupplierDialog(context),
              child: const Text('Add Your First Supplier'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(SupplierModel supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete supplier ${supplier.supplierName}? This will only work if there are no linked payments or orders.',
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
      try {
        await _supplierService.deleteSupplier(
          widget.user.companyId!,
          supplier.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _showAddSupplierDialog(BuildContext context) {
    SidePanel.show(
      context: context,
      title: 'Add New Supplier',
      child: AddSupplierDialog(companyId: widget.user.companyId!),
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
