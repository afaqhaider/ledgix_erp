import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:uuid/uuid.dart';

class UomPane extends StatefulWidget {
  final AppUser user;
  final UomModel? uom;
  const UomPane({super.key, required this.user, this.uom});

  @override
  State<UomPane> createState() => _UomPaneState();
}

class _UomPaneState extends State<UomPane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _precisionController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.uom?.uomCode);
    _nameController = TextEditingController(text: widget.uom?.uomName);
    _precisionController = TextEditingController(
      text: widget.uom?.decimalPrecision.toString() ?? '0',
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'UOM Code*'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'UOM Name*'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _precisionController,
            decoration: const InputDecoration(labelText: 'Decimal Precision'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final uom = UomModel(
                id: widget.uom?.id ?? const Uuid().v4(),
                companyId: widget.user.companyId!,
                uomCode: _codeController.text.trim(),
                uomName: _nameController.text.trim(),
                decimalPrecision: int.tryParse(_precisionController.text) ?? 0,
              );
              await inventoryService.addUom(uom);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save UOM'),
          ),
        ],
      ),
    );
  }
}
