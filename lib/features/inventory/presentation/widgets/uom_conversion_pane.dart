import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:uuid/uuid.dart';

class UomConversionPane extends StatefulWidget {
  final AppUser user;
  final UomConversionModel? conversion;
  const UomConversionPane({super.key, required this.user, this.conversion});

  @override
  State<UomConversionPane> createState() => _UomConversionPaneState();
}

class _UomConversionPaneState extends State<UomConversionPane> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();

  String? _fromUomId;
  String? _toUomId;
  String? _itemId;
  late TextEditingController _factorController;

  @override
  void initState() {
    super.initState();
    _fromUomId = widget.conversion?.fromUomId;
    _toUomId = widget.conversion?.toUomId;
    _itemId = widget.conversion?.itemId;
    _factorController = TextEditingController(
      text: widget.conversion?.conversionFactor.toString() ?? '1.0',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          StreamBuilder<List<InventoryItemModel>>(
            stream: _inventoryService.getInventoryItems(widget.user.companyId!),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              return DropdownButtonFormField<String>(
                initialValue: _itemId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Global (All Items)'),
                  ),
                  ...items.map(
                    (i) =>
                        DropdownMenuItem(value: i.id, child: Text(i.itemName)),
                  ),
                ],
                onChanged: (v) => setState(() => _itemId = v),
                decoration: const InputDecoration(labelText: 'Applicable Item'),
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<UomModel>>(
            stream: _inventoryService.getUoms(widget.user.companyId!),
            builder: (context, snapshot) {
              final uoms = snapshot.data ?? [];
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _fromUomId,
                    items: uoms
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.uomName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _fromUomId = v),
                    decoration: const InputDecoration(labelText: 'From UOM*'),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _toUomId,
                    items: uoms
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.uomName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _toUomId = v),
                    decoration: const InputDecoration(labelText: 'To UOM*'),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _factorController,
            decoration: const InputDecoration(labelText: 'Conversion Factor*'),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final conv = UomConversionModel(
                id: widget.conversion?.id ?? const Uuid().v4(),
                companyId: widget.user.companyId!,
                itemId: _itemId,
                fromUomId: _fromUomId!,
                toUomId: _toUomId!,
                conversionFactor:
                    double.tryParse(_factorController.text) ?? 1.0,
              );
              await _inventoryService.addUomConversion(conv);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save Conversion'),
          ),
        ],
      ),
    );
  }
}
