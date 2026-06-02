import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../models/product_model.dart';
import '../../services/inventory_service.dart';

class ProductFormScreen extends StatefulWidget {
  final AppUser user;
  final ProductModel? product;
  const ProductFormScreen({super.key, required this.user, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();

  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _uomController;
  late TextEditingController _salePriceController;
  late TextEditingController _costPriceController;
  late TextEditingController _initialStockController;

  ProductType _selectedType = ProductType.storable;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _uomController = TextEditingController(
      text: widget.product?.uom ?? 'Units',
    );
    _salePriceController = TextEditingController(
      text: widget.product?.salePrice.toString() ?? '0.0',
    );
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice.toString() ?? '0.0',
    );
    _initialStockController = TextEditingController(
      text: widget.product?.stockQuantity.toString() ?? '0.0',
    );
    _selectedType = widget.product?.type ?? ProductType.storable;
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _uomController.dispose();
    _salePriceController.dispose();
    _costPriceController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final product = ProductModel(
        id: widget.product?.id ?? '',
        companyId: widget.user.companyId!,
        sku: _skuController.text,
        name: _nameController.text,
        description: _descriptionController.text,
        type: _selectedType,
        uom: _uomController.text,
        salePrice: double.parse(_salePriceController.text),
        costPrice: double.parse(_costPriceController.text),
        stockQuantity: double.parse(_initialStockController.text),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      if (widget.product == null) {
        await _inventoryService.addProduct(product);
      } else {
        await _inventoryService.updateProduct(product);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProductType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Product Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ProductType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _uomController,
                    decoration: const InputDecoration(
                      labelText: 'Unit of Measure',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Sale Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Cost Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _initialStockController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Stock',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: widget.product == null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('SAVE PRODUCT'),
                  ),
                ],
              ),
            ),
    );
  }
}
