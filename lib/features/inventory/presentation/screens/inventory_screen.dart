import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../services/inventory_service.dart';
import '../../models/product_model.dart';
import 'package:intl/intl.dart';
import 'product_form_screen.dart';

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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductFormScreen(user: widget.user),
              ),
            ),
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
                  DataColumn(
                    label: Text('Stock Quantity', textAlign: TextAlign.right),
                    numeric: true,
                  ),
                  DataColumn(label: Text('UOM')),
                  DataColumn(
                    label: Text('Sale Price', textAlign: TextAlign.right),
                    numeric: true,
                  ),
                  DataColumn(label: Text('Actions')),
                ],
                rows: products
                    .map(
                      (product) => DataRow(
                        cells: [
                          DataCell(Text(product.sku)),
                          DataCell(Text(product.name)),
                          DataCell(Text(product.type.name.toUpperCase())),
                          DataCell(
                            Text(
                              product.stockQuantity.toString(),
                              style: TextStyle(
                                color: product.stockQuantity < 10
                                    ? Colors.red
                                    : null,
                                fontWeight: product.stockQuantity < 10
                                    ? FontWeight.bold
                                    : null,
                              ),
                            ),
                          ),
                          DataCell(Text(product.uom)),
                          DataCell(
                            Text(
                              NumberFormat.simpleCurrency().format(
                                product.salePrice,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductFormScreen(
                                        user: widget.user,
                                        product: product,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.exposure, size: 20),
                                  tooltip: 'Stock Adjustment',
                                  onPressed: () =>
                                      _showAdjustmentDialog(context, product),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context, ProductModel product) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    bool isAddition = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Add'),
                      value: true,
                      // ignore: deprecated_member_use
                      groupValue: isAddition,
                      // ignore: deprecated_member_use
                      onChanged: (v) => setDialogState(() => isAddition = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Remove'),
                      value: false,
                      // ignore: deprecated_member_use
                      groupValue: isAddition,
                      // ignore: deprecated_member_use
                      onChanged: (v) => setDialogState(() => isAddition = v!),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = double.tryParse(qtyController.text) ?? 0;
                if (qty <= 0) return;

                await _inventoryService.recordStockAdjustment(
                  companyId: widget.user.companyId!,
                  productId: product.id,
                  quantity: isAddition ? qty : -qty,
                  reason: reasonController.text,
                  userId: widget.user.uid,
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Adjustment'),
            ),
          ],
        ),
      ),
    );
  }
}
