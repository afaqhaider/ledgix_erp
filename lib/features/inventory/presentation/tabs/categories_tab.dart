import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import '../../models/inventory_models.dart';
import '../../services/inventory_service.dart';
import '../widgets/category_pane.dart';

class CategoriesTab extends StatelessWidget {
  final AppUser user;
  const CategoriesTab({super.key, required this.user});

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
              const Text('Item Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => SidePanel.show(context: context, title: 'Add Category', child: CategoryPane(user: user)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<InventoryCategoryModel>>(
            stream: inventoryService.getCategories(user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final cats = snapshot.data ?? [];
              return ListView.builder(
                itemCount: cats.length,
                itemBuilder: (context, index) {
                  final cat = cats[index];
                  return ListTile(
                    dense: true,
                    title: Text(cat.name, style: const TextStyle(fontSize: 12)),
                    subtitle: Text(cat.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, color: cat.isActive ? Colors.green : Colors.red)),
                    onTap: () => SidePanel.show(context: context, title: 'Edit Category', child: CategoryPane(user: user, category: cat)),
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
