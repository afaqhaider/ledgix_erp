import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/stock_movement_models.dart';
import '../widgets/transfer_pane.dart';

class TransfersTab extends StatelessWidget {
  final AppUser user;
  const TransfersTab({super.key, required this.user});

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
              const Text('Inventory Transfers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => SidePanel.show(context: context, title: 'New Transfer', child: TransferPane(user: user)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('companies').doc(user.companyId!).collection('inventoryTransfers').orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final t = InventoryTransferModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
                  return ListTile(
                    dense: true,
                    title: Text(t.transferNumber, style: const TextStyle(fontSize: 12)),
                    subtitle: Text('From ${t.sourceWarehouseId} to ${t.destinationWarehouseId}', style: const TextStyle(fontSize: 10)),
                    trailing: Text('${t.items.length} items', style: const TextStyle(fontSize: 10)),
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
