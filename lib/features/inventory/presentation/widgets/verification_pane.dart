import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/inventory/models/inventory_models.dart';
import 'package:ledgixerp/features/inventory/models/stock_movement_models.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class VerificationPane extends StatefulWidget {
  final AppUser user;
  const VerificationPane({super.key, required this.user});

  @override
  State<VerificationPane> createState() => _VerificationPaneState();
}

class _VerificationPaneState extends State<VerificationPane> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _firestore = FirebaseFirestore.instance;

  late TextEditingController _numberController;
  final DateTime _date = DateTime.now();
  String? _warehouseId;
  List<VerificationItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: 'CNT-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  void _loadSystemStock() async {
    if (_warehouseId == null) return;
    final items = await _inventoryService
        .getInventoryItems(widget.user.companyId!)
        .first;
    final List<VerificationItemModel> vItems = [];
    for (var item in items) {
      final balanceDoc = await _firestore
          .collection('companies')
          .doc(widget.user.companyId!)
          .collection('stockBalances')
          .doc('${item.id}_$_warehouseId')
          .get();
      double sysQty = 0.0;
      if (balanceDoc.exists) {
        sysQty = (balanceDoc.data() as Map<String, dynamic>)['quantity'] ?? 0.0;
      }
      vItems.add(
        VerificationItemModel(
          itemId: item.id,
          itemCode: item.itemCode,
          itemName: item.itemName,
          systemQuantity: sysQty,
          physicalQuantity: sysQty,
          variance: 0,
        ),
      );
    }
    setState(() => _items = vItems);
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
              decoration: const InputDecoration(labelText: 'Count Number*'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
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
                  onChanged: (v) {
                    setState(() => _warehouseId = v);
                    _loadSystemStock();
                  },
                  decoration: const InputDecoration(labelText: 'Warehouse*'),
                  validator: (v) => v == null ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification Items',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.itemCode} - ${item.itemName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'System: ${item.systemQuantity}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.physicalQuantity.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Physical',
                              labelStyle: TextStyle(fontSize: 10),
                            ),
                            onChanged: (v) {
                              double phys = double.tryParse(v) ?? 0;
                              setState(() {
                                _items[i] = VerificationItemModel(
                                  itemId: item.itemId,
                                  itemCode: item.itemCode,
                                  itemName: item.itemName,
                                  systemQuantity: item.systemQuantity,
                                  physicalQuantity: phys,
                                  variance: phys - item.systemQuantity,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Var: ${item.variance}',
                            style: TextStyle(
                              fontSize: 10,
                              color: item.variance != 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
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
                final pv = PhysicalVerificationModel(
                  id: const Uuid().v4(),
                  companyId: widget.user.companyId!,
                  countNumber: _numberController.text.trim(),
                  warehouseId: _warehouseId!,
                  date: _date,
                  items: _items,
                  createdBy: widget.user.uid,
                );
                await _firestore
                    .collection('companies')
                    .doc(widget.user.companyId!)
                    .collection('physicalVerifications')
                    .doc(pv.id)
                    .set(pv.toMap());
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Count'),
            ),
          ],
        ),
      ),
    );
  }
}
