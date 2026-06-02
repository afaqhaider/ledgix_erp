import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../services/inventory_service.dart';
import '../../models/product_model.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  final AppUser user;
  const InventoryScreen({super.key, required this.user});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _inventoryService = InventoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _inventoryService.getProducts(widget.user.companyId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Product Name')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Stock Quantity', textAlign: TextAlign.right), numeric: true),
                  DataColumn(label: Text('UOM')),
                  DataColumn(label: Text('Sale Price', textAlign: TextAlign.right), numeric: true),
                  DataColumn(label: Text('Actions')),
                ],
                rows: products.map((product) => DataRow(
                  cells: [
                    DataCell(Text(product.sku)),
                    DataCell(Text(product.name)),
                    DataCell(Text(product.type.name.toUpperCase())),
                    DataCell(Text(
                      product.stockQuantity.toString(),
                      style: TextStyle(
                        color: product.stockQuantity < 10 ? Colors.red : null,
                        fontWeight: product.stockQuantity < 10 ? FontWeight.bold : null,
                      ),
                    )),
                    DataCell(Text(product.uom)),
                    DataCell(Text(NumberFormat.simpleCurrency().format(product.salePrice))),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.history, size: 20),
                          onPressed: () {},
                        ),
                      ],
                    )),
                  ],
                )).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    // Basic implementation of add product dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: const Text('Product addition form would go here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }
}
