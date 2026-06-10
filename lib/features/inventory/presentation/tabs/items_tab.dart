import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/widgets/erp_dialogs.dart';
import 'package:ledgixerp/core/widgets/erp_layout.dart';
import 'package:ledgixerp/core/widgets/erp_data_table.dart';
import 'package:ledgixerp/core/widgets/erp_status_badge.dart';
import 'package:ledgixerp/widgets/erp_ui_components.dart';
import '../../models/inventory_models.dart';
import '../../services/inventory_service.dart';
import '../widgets/inventory_item_pane.dart';

class ItemsTab extends StatelessWidget {
  final AppUser user;
  const ItemsTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ERPActionToolbar(
            searchField: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () => showErpSidePane(
                  context: context,
                  builder: InventoryItemPane(user: user),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<InventoryItemModel>>(
              stream: inventoryService.getInventoryItems(user.companyId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return ERPEmptyState(
                    title: 'No items found',
                    message: 'Get started by adding your first inventory item',
                    icon: Icons.inventory_2_outlined,
                    action: ElevatedButton.icon(
                      onPressed: () => showErpSidePane(
                        context: context,
                        builder: InventoryItemPane(user: user),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Item'),
                    ),
                  );
                }

                return ERPDataTable<InventoryItemModel>(
                  columns: const [
                    'CODE',
                    'NAME',
                    'TYPE',
                    'CATEGORY',
                    'SALES PRICE',
                    'STATUS',
                    '',
                  ],
                  items: items,
                  rowBuilder: (item, index) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item.itemCode,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(Text(item.itemType.label, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(item.itemCategoryId ?? '-', style: const TextStyle(fontSize: 12))),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              AppFormatters.currency(item.salesPrice),
                              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        DataCell(
                          ERPStatusBadge.fromStatus(
                            item.isActive ? 'Active' : 'Inactive',
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => showErpSidePane(
                                  context: context,
                                  builder: InventoryItemPane(user: user, item: item),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(context, inventoryService, item),
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

  void _confirmDelete(BuildContext context, InventoryService service, InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (_) => ERPConfirmDeleteDialog(
        title: 'Delete Item',
        message: 'Are you sure you want to delete item ${item.itemName}? This action cannot be undone.',
        onConfirm: () async {
          try {
            await service.deleteItem(user.companyId!, item.id);
          } catch (e) {
            if (context.mounted) showErpError(context: context, error: e);
          }
        },
      ),
    );
  }
}
