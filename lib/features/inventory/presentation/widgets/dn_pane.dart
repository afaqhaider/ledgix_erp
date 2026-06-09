import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/models/stock_movement_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:ledgixerp/features/inventory/services/stock_movement_service.dart';
import 'package:ledgixerp/features/crm/customers/models/customer_model.dart';
import 'package:ledgixerp/features/crm/customers/services/customer_service.dart';
import 'package:uuid/uuid.dart';

class DnPane extends StatefulWidget {
  final AppUser user;
  const DnPane({super.key, required this.user});

  @override
  State<DnPane> createState() => _DnPaneState();
}

class _DnPaneState extends State<DnPane> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _movementService = StockMovementService();
  final _customerService = CustomerService();

  late TextEditingController _numberController;
  DateTime _date = DateTime.now();
  String? _customerId;
  String? _warehouseId;
  final List<StockItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: 'DN-${DateTime.now().millisecondsSinceEpoch}',
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
              decoration: const InputDecoration(labelText: 'DN Number*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Date'),
              subtitle: Text('${_date.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<CustomerModel>>(
              stream: _customerService.getCustomers(widget.user.companyId!),
              builder: (context, snapshot) {
                final customers = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _customerId,
                  items: customers
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _customerId = v),
                  decoration: const InputDecoration(labelText: 'Customer*'),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<WarehouseModel>>(
              stream: _inventoryService.getWarehouses(widget.user.companyId!),
              builder: (context, snapshot) {
                final whs = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _warehouseId,
                  items: whs
                      .map(
                        (w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(w.warehouseName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _warehouseId = v),
                  decoration: const InputDecoration(labelText: 'Warehouse*'),
                  validator: (v) => v == null ? 'Required' : null,
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
                final dn = DeliveryNoteModel(
                  id: const Uuid().v4(),
                  companyId: widget.user.companyId!,
                  dnNumber: _numberController.text.trim(),
                  customerId: _customerId!,
                  warehouseId: _warehouseId!,
                  date: _date,
                  items: _items,
                  createdBy: widget.user.uid,
                );
                await _movementService.createDn(dn);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Deliver Stock'),
            ),
          ],
        ),
      ),
    );
  }
}
