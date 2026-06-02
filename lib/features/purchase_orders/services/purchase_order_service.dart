import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/purchase_orders/models/purchase_order_model.dart';
import '../../settings/services/financial_settings_service.dart';

class PurchaseOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

  CollectionReference _getPORef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('purchaseOrders');
  }

  Stream<List<PurchaseOrderModel>> getPurchaseOrders(String companyId) {
    return _getPORef(
      companyId,
    ).orderBy('poDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PurchaseOrderModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<String> generateNextPONumber(String companyId) async {
    return await _settingsService.generateNextDocumentNumber(companyId, 'purchaseOrder');
  }

  Future<void> addPurchaseOrder(PurchaseOrderModel po) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(po.companyId, po.poDate)) {
      throw Exception('Accounting period for this date is locked.');
    }
    await _getPORef(po.companyId).doc().set(po.toMap());
  }

  Future<void> updatePOStatus(
    String companyId,
    String poId,
    POStatus status,
  ) async {
    await _getPORef(companyId).doc(poId).update({'status': status.name});
  }
}
