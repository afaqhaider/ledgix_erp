import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/purchase_orders/models/purchase_order_model.dart';

class PurchaseOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getPORef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('purchaseOrders');
  }

  Stream<List<PurchaseOrderModel>> getPurchaseOrders(String companyId) {
    return _getPORef(companyId)
        .orderBy('poDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PurchaseOrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<String> generateNextPONumber(String companyId) async {
    final snapshot = await _getPORef(companyId)
        .orderBy('poNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'PO-0001';
    }

    final lastNumberStr = snapshot.docs.first.get('poNumber') as String;
    final numberMatch = RegExp(r'\d+').firstMatch(lastNumberStr);
    if (numberMatch != null) {
      final lastNumber = int.parse(numberMatch.group(0)!);
      final nextNumber = lastNumber + 1;
      return 'PO-${nextNumber.toString().padLeft(4, '0')}';
    }

    return 'PO-0001';
  }

  Future<void> addPurchaseOrder(PurchaseOrderModel po) async {
    await _getPORef(po.companyId).doc().set(po.toMap());
  }

  Future<void> updatePOStatus(String companyId, String poId, POStatus status) async {
    await _getPORef(companyId).doc(poId).update({'status': status.name});
  }
}
