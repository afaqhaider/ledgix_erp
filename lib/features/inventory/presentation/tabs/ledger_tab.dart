import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:intl/intl.dart';
import '../../models/stock_movement_models.dart';
import '../../services/stock_movement_service.dart';

class LedgerTab extends StatelessWidget {
  final AppUser user;
  const LedgerTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final movementService = StockMovementService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Stock Ledger',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<StockLedgerModel>>(
            stream: movementService.getStockLedger(user.companyId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snapshot.data ?? [];

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 40,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Ref')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Warehouse')),
                      DataColumn(label: Text('In', textAlign: TextAlign.right)),
                      DataColumn(
                        label: Text('Out', textAlign: TextAlign.right),
                      ),
                      DataColumn(
                        label: Text('Balance', textAlign: TextAlign.right),
                      ),
                    ],
                    rows: entries
                        .map(
                          (e) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm').format(e.date),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              DataCell(
                                Text(
                                  e.referenceNumber,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              DataCell(
                                Text(
                                  e.referenceType,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              DataCell(
                                Text(
                                  e.warehouseId,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    e.quantityIn > 0
                                        ? e.quantityIn.toString()
                                        : '-',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    e.quantityOut > 0
                                        ? e.quantityOut.toString()
                                        : '-',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    e.balanceAfter.toString(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
        ),
      ],
    );
  }
}
