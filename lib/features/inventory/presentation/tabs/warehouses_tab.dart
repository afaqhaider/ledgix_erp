import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import '../../models/inventory_models.dart';
import '../../services/inventory_service.dart';
import '../widgets/warehouse_pane.dart';

class WarehousesTab extends StatelessWidget {
  final AppUser user;
  const WarehousesTab({super.key, required this.user});

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
              const Text('Warehouses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => SidePanel.show(context: context, title: 'Add Warehouse', child: WarehousePane(user: user)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<WarehouseModel>>(
            stream: inventoryService.getWarehouses(user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final warehouses = snapshot.data ?? [];
              return ListView.builder(
                itemCount: warehouses.length,
                itemBuilder: (context, index) {
                  final wh = warehouses[index];
                  return ListTile(
                    dense: true,
                    title: Text(wh.warehouseName, style: const TextStyle(fontSize: 12)),
                    subtitle: Text(wh.warehouseCode, style: const TextStyle(fontSize: 10)),
                    trailing: Text(wh.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, color: wh.isActive ? Colors.green : Colors.red)),
                    onTap: () => SidePanel.show(context: context, title: 'Edit Warehouse', child: WarehousePane(user: user, warehouse: wh)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
