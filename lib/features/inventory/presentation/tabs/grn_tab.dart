import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/stock_movement_models.dart';
import '../widgets/grn_pane.dart';

class GrnTab extends StatelessWidget {
  final AppUser user;
  const GrnTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Goods Receipt Notes (GRN)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => SidePanel.show(context: context, title: 'Add GRN', child: GrnPane(user: user)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('companies').doc(user.companyId!).collection('grns').orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 30,
                    dataRowMaxHeight: 40,
                    columns: const [
                      DataColumn(label: Text('GRN #')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Supplier')),
                      DataColumn(label: Text('Warehouse')),
                      DataColumn(label: Text('Items')),
                    ],
                    rows: docs.map((doc) {
                      final grn = GrnModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                      return DataRow(
                        cells: [
                          DataCell(Text(grn.grnNumber, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(DateFormat('yyyy-MM-dd').format(grn.date), style: const TextStyle(fontSize: 12))),
                          DataCell(Text(grn.supplierId, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(grn.warehouseId, style: const TextStyle(fontSize: 12))),
                          DataCell(Text('${grn.items.length} items', style: const TextStyle(fontSize: 12))),
                        ],
                        onSelectChanged: (_) {
                           // View details or edit if allowed
                        },
                      );
                    }).toList(),
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
