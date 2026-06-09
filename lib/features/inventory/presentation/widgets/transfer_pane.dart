import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/models/stock_movement_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/inventory/services/stock_movement_service.dart';
import 'package:uuid/uuid.dart';

class TransferPane extends StatefulWidget {
  final AppUser user;
  const TransferPane({super.key, required this.user});

  @override
  State<TransferPane> createState() => _TransferPaneState();
}

class _TransferPaneState extends State<TransferPane> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _movementService = StockMovementService();

  late TextEditingController _numberController;
  final DateTime _date = DateTime.now();
  String? _sourceWhId;
  String? _destWhId;
  final List<StockItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: 'TRF-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Transfer Number*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<WarehouseModel>>(
              stream: _inventoryService.getWarehouses(widget.user.companyId!),
              builder: (context, snapshot) {
                final whs = snapshot.data ?? [];
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _sourceWhId,
                      items: whs
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.warehouseName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _sourceWhId = v),
                      decoration: const InputDecoration(
                        labelText: 'Source Warehouse*',
                      ),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _destWhId,
                      items: whs
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.warehouseName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _destWhId = v),
                      decoration: const InputDecoration(
                        labelText: 'Destination Warehouse*',
                      ),
                      validator: (v) => v == null
                          ? 'Required'
                          : (v == _sourceWhId ? 'Must be different' : null),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(
                    () => _items.add(
                      StockItemModel(
                        itemId: '',
                        itemCode: '',
                        itemName: '',
                        quantity: 1,
                        uomId: '',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const Divider(),
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: StreamBuilder<List<InventoryItemModel>>(
                        stream: _inventoryService.getInventoryItems(
                          widget.user.companyId!,
                        ),
                        builder: (context, snapshot) {
                          final items = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            initialValue: _items[i].itemId.isEmpty
                                ? null
                                : _items[i].itemId,
                            items: items
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.itemName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              final selected = items.firstWhere(
                                (it) => it.id == v,
                              );
                              setState(() {
                                _items[i] = StockItemModel(
                                  itemId: selected.id,
                                  itemCode: selected.itemCode,
                                  itemName: selected.itemName,
                                  quantity: _items[i].quantity,
                                  uomId: selected.defaultUomId,
                                );
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Select Item',
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        initialValue: _items[i].quantity.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _items[i] = StockItemModel(
                          itemId: _items[i].itemId,
                          itemCode: _items[i].itemCode,
                          itemName: _items[i].itemName,
                          quantity: double.tryParse(v) ?? 0,
                          uomId: _items[i].uomId,
                        ),
                        decoration: const InputDecoration(hintText: 'Qty'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _items.removeAt(i)),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (_items.isEmpty) return;
                final trf = InventoryTransferModel(
                  id: const Uuid().v4(),
                  companyId: widget.user.companyId!,
                  transferNumber: _numberController.text.trim(),
                  sourceWarehouseId: _sourceWhId!,
                  destinationWarehouseId: _destWhId!,
                  date: _date,
                  items: _items,
                  createdBy: widget.user.uid,
                );
                await _movementService.createTransfer(trf);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Transfer Stock'),
            ),
          ],
        ),
      ),
    );
  }
}
