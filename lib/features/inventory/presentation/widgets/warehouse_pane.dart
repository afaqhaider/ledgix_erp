import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:uuid/uuid.dart';

class WarehousePane extends StatefulWidget {
  final AppUser user;
  final WarehouseModel? warehouse;
  const WarehousePane({super.key, required this.user, this.warehouse});

  @override
  State<WarehousePane> createState() => _WarehousePaneState();
}

class _WarehousePaneState extends State<WarehousePane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactNumberController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.warehouse?.warehouseCode,
    );
    _nameController = TextEditingController(
      text: widget.warehouse?.warehouseName,
    );
    _addressController = TextEditingController(text: widget.warehouse?.address);
    _contactPersonController = TextEditingController(
      text: widget.warehouse?.contactPerson,
    );
    _contactNumberController = TextEditingController(
      text: widget.warehouse?.contactNumber,
    );
    _isActive = widget.warehouse?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Warehouse Code*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Warehouse Name*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactPersonController,
              decoration: const InputDecoration(labelText: 'Contact Person'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactNumberController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
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
                final wh = WarehouseModel(
                  id: widget.warehouse?.id ?? const Uuid().v4(),
                  companyId: widget.user.companyId!,
                  warehouseCode: _codeController.text.trim(),
                  warehouseName: _nameController.text.trim(),
                  address: _addressController.text.trim(),
                  contactPerson: _contactPersonController.text.trim(),
                  contactNumber: _contactNumberController.text.trim(),
                  isActive: _isActive,
                );
                await inventoryService.addWarehouse(wh);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Warehouse'),
            ),
          ],
        ),
      ),
    );
  }
}
