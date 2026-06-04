import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/inventory_models.dart';
import '../../services/inventory_service.dart';

class BalanceReportTab extends StatefulWidget {
  final AppUser user;
  const BalanceReportTab({super.key, required this.user});

  @override
  State<BalanceReportTab> createState() => _BalanceReportTabState();
}

class _BalanceReportTabState extends State<BalanceReportTab> {
  final _inventoryService = InventoryService();
  final _firestore = FirebaseFirestore.instance;
  String? _selectedWarehouse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Stock Balance Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              StreamBuilder<List<WarehouseModel>>(
                stream: _inventoryService.getWarehouses(widget.user.companyId!),
                builder: (context, snapshot) {
                  final whs = snapshot.data ?? [];
                  return SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _selectedWarehouse,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Warehouses')),
                        ...whs.map((w) => DropdownMenuItem(
                            value: w.id, child: Text(w.warehouseName))),
                      ],
                      onChanged: (v) => setState(() => _selectedWarehouse = v),
                      decoration: const InputDecoration(
                          isDense: true, labelText: 'Filter Warehouse'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<InventoryItemModel>>(
            stream: _inventoryService.getInventoryItems(widget.user.companyId!),
            builder: (context, itemSnapshot) {
              if (itemSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = itemSnapshot.data ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('companies')
                    .doc(widget.user.companyId!)
                    .collection('stockBalances')
                    .snapshots(),
                builder: (context, balanceSnapshot) {
                  final balances = balanceSnapshot.data?.docs ?? [];

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 40,
                        dataRowMinHeight: 30,
                        dataRowMaxHeight: 40,
                        columns: const [
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('Item Name')),
                          DataColumn(label: Text('UOM')),
                          DataColumn(
                              label: Text('Stock', textAlign: TextAlign.right)),
                          DataColumn(
                              label: Text('Reorder Level',
                                  textAlign: TextAlign.right)),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: items.map((item) {
                          double totalStock = 0;
                          if (_selectedWarehouse == null) {
                            totalStock = balances
                                .where((b) => b.get('itemId') == item.id)
                                .fold(0.0,
                                    (sum, b) => sum + (b.get('quantity') ?? 0.0));
                          } else {
                            final b = balances
                                .cast<QueryDocumentSnapshot?>()
                                .firstWhere(
                                    (b) =>
                                        b!.get('itemId') == item.id &&
                                        b.get('warehouseId') ==
                                            _selectedWarehouse,
                                    orElse: () => null);
                            totalStock = b?.get('quantity') ?? 0.0;
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text(item.itemCode,
                                  style: const TextStyle(fontSize: 11))),
                              DataCell(Text(item.itemName,
                                  style: const TextStyle(fontSize: 11))),
                              DataCell(Text(item.defaultUomId,
                                  style: const TextStyle(fontSize: 11))),
                              DataCell(Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(totalStock.toString(),
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: totalStock < item.reorderLevel
                                              ? Colors.red
                                              : null)))),
                              DataCell(Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(item.reorderLevel.toString(),
                                      style: const TextStyle(fontSize: 11)))),
                              DataCell(Text(
                                  totalStock < item.reorderLevel
                                      ? 'Reorder'
                                      : 'OK',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: totalStock < item.reorderLevel
                                          ? Colors.red
                                          : Colors.green))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
