import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:uuid/uuid.dart';

class CategoryPane extends StatefulWidget {
  final AppUser user;
  final InventoryCategoryModel? category;
  const CategoryPane({super.key, required this.user, this.category});

  @override
  State<CategoryPane> createState() => _CategoryPaneState();
}

class _CategoryPaneState extends State<CategoryPane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _parentId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _parentId = widget.category?.parentCategoryId;
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Category Name*'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<InventoryCategoryModel>>(
            stream: inventoryService.getCategories(widget.user.companyId!),
            builder: (context, snapshot) {
              final cats = snapshot.data ?? [];
              return DropdownButtonFormField<String>(
                initialValue: _parentId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None (Top Level)'),
                  ),
                  ...cats
                      .where((c) => c.id != widget.category?.id)
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                ],
                onChanged: (v) => setState(() => _parentId = v),
                decoration: const InputDecoration(labelText: 'Parent Category'),
              );
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Is Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final cat = InventoryCategoryModel(
                id: widget.category?.id ?? const Uuid().v4(),
                companyId: widget.user.companyId!,
                name: _nameController.text.trim(),
                parentCategoryId: _parentId,
                isActive: _isActive,
              );
              await inventoryService.addCategory(cat);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save Category'),
          ),
        ],
      ),
    );
  }
}
