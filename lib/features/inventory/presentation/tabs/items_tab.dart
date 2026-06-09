import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/utils/app_formatters.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import '../../models/inventory_models.dart';
import '../../services/inventory_service.dart';
import '../widgets/inventory_item_pane.dart';

class ItemsTab extends StatelessWidget {
  final AppUser user;
  const ItemsTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Inventory Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => SidePanel.show(
                  context: context,
                  title: 'Add New Item',
                  child: InventoryItemPane(user: user),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<InventoryItemModel>>(
            stream: inventoryService.getInventoryItems(user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 40,
                    columns: const [
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Category')),
                      DataColumn(
                        label: Text('Sales Price', textAlign: TextAlign.right),
                      ),
                      DataColumn(
                        label: Text('Stock', textAlign: TextAlign.right),
                      ),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: items
                        .map(
                          (item) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  item.itemCode,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.itemName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.itemType.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.itemCategoryId ?? '-',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    AppFormatters.currency(item.salesPrice),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '0.00',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ), // Stock balance placeholder
                              DataCell(
                                Text(
                                  item.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.isActive
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                            onSelectChanged: (_) => SidePanel.show(
                              context: context,
                              title: 'Edit Item',
                              child: InventoryItemPane(user: user, item: item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
