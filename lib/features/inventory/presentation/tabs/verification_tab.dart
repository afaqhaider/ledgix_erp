import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/stock_movement_models.dart';
import '../../services/stock_movement_service.dart';
import '../widgets/verification_pane.dart';

class VerificationTab extends StatelessWidget {
  final AppUser user;
  const VerificationTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final movementService = StockMovementService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Physical Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => SidePanel.show(context: context, title: 'New Verification', child: VerificationPane(user: user)),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('companies').doc(user.companyId!).collection('physicalVerifications').orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data?.docs ?? [];
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final v = PhysicalVerificationModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
                  return ListTile(
                    dense: true,
                    title: Text(v.countNumber, style: const TextStyle(fontSize: 12)),
                    subtitle: Text('Warehouse: ${v.warehouseId} | Status: ${v.status}', style: const TextStyle(fontSize: 10)),
                    trailing: v.status == 'draft' 
                      ? ElevatedButton(onPressed: () => movementService.approveVerification(v), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)), child: const Text('Approve', style: TextStyle(fontSize: 10)))
                      : const Icon(Icons.check_circle, color: Colors.green, size: 20),
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
