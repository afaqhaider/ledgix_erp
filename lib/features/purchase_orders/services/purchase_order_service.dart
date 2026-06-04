import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/purchase_orders/models/purchase_order_model.dart';
import 'package:ledgixerp/features/inventory/services/inventory_service.dart';
import '../../settings/services/financial_settings_service.dart';

class PurchaseOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();
  final _inventoryService = InventoryService();

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
    return await _settingsService.previewNextDocumentNumber(
      companyId,
      'purchaseOrder',
    );
  }

  Future<void> addPurchaseOrder(PurchaseOrderModel po) async {
    // Check if period is locked
    if (await _settingsService.isPeriodLocked(po.companyId, po.poDate)) {
      throw Exception('Accounting period for this date is locked.');
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Generate final number and increment within transaction
      final finalNumber = await _settingsService.getNextDocumentNumberAndIncrement(
        po.companyId,
        'purchaseOrder',
        transaction: transaction,
      );

      final docRef = _getPORef(po.companyId).doc();
      final finalPO = po.copyWith(
        id: docRef.id,
        poNumber: finalNumber,
      );

      // 2. Save PO
      transaction.set(docRef, finalPO.toMap());
    });
  }

  Future<void> receiveStock(String companyId, String poId) async {
    final doc = await _getPORef(companyId).doc(poId).get();
    if (!doc.exists) throw Exception('Purchase Order not found');

    final po = PurchaseOrderModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
    if (po.isReceived) throw Exception('Stock already received for this PO');

    // 1. Update Inventory for each item
    for (var item in po.items) {
      if (item.productId != null && item.productId!.isNotEmpty) {
        await _inventoryService.recordPurchase(
          companyId: companyId,
          productId: item.productId!,
          quantity: item.quantity,
          unitCost: item.unitPrice,
          purchaseId: poId,
        );
      }
    }

    // 2. Mark PO as Received
    await _getPORef(companyId).doc(poId).update({
      'isReceived': true,
      'status': POStatus.received.name,
      'approvalStatus': 'approved',
    });
  }

  Future<void> updatePOStatus(
    String companyId,
    String poId,
    POStatus status,
  ) async {
    await _getPORef(companyId).doc(poId).update({'status': status.name});
  }
}
