import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_movement_models.dart';

class StockMovementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getRef(String companyId, String collection) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection(collection);
  }

  Future<void> createGrn(GrnModel grn) async {
    final batch = _firestore.batch();
    final grnRef = _getRef(grn.companyId, 'grns').doc();
    batch.set(grnRef, grn.toMap());

    for (var item in grn.items) {
      await _updateStock(
        companyId: grn.companyId,
        itemId: item.itemId,
        warehouseId: grn.warehouseId,
        quantityChange: item.quantity,
        referenceType: 'GRN',
        referenceNumber: grn.grnNumber,
        date: grn.date,
        batch: batch,
      );
    }
    await batch.commit();
  }

  Future<void> createDn(DeliveryNoteModel dn) async {
    final batch = _firestore.batch();
    final dnRef = _getRef(dn.companyId, 'deliveryNotes').doc();
    batch.set(dnRef, dn.toMap());

    for (var item in dn.items) {
      await _updateStock(
        companyId: dn.companyId,
        itemId: item.itemId,
        warehouseId: dn.warehouseId,
        quantityChange: -item.quantity,
        referenceType: 'DN',
        referenceNumber: dn.dnNumber,
        date: dn.date,
        batch: batch,
      );
    }
    await batch.commit();
  }

  Future<void> createTransfer(InventoryTransferModel transfer) async {
    final batch = _firestore.batch();
    final transferRef = _getRef(transfer.companyId, 'inventoryTransfers').doc();
    batch.set(transferRef, transfer.toMap());

    for (var item in transfer.items) {
      // Out from source
      await _updateStock(
        companyId: transfer.companyId,
        itemId: item.itemId,
        warehouseId: transfer.sourceWarehouseId,
        quantityChange: -item.quantity,
        referenceType: 'Transfer Out',
        referenceNumber: transfer.transferNumber,
        date: transfer.date,
        batch: batch,
      );
      // In to destination
      await _updateStock(
        companyId: transfer.companyId,
        itemId: item.itemId,
        warehouseId: transfer.destinationWarehouseId,
        quantityChange: item.quantity,
        referenceType: 'Transfer In',
        referenceNumber: transfer.transferNumber,
        date: transfer.date,
        batch: batch,
      );
    }
    await batch.commit();
  }

  Future<void> approveVerification(PhysicalVerificationModel pv) async {
    final batch = _firestore.batch();
    final pvRef = _getRef(pv.companyId, 'physicalVerifications').doc(pv.id);
    batch.update(pvRef, {'status': 'approved'});

    for (var item in pv.items) {
      if (item.variance != 0) {
        await _updateStock(
          companyId: pv.companyId,
          itemId: item.itemId,
          warehouseId: pv.warehouseId,
          quantityChange: item.variance,
          referenceType: 'Adjustment',
          referenceNumber: pv.countNumber,
          date: pv.date,
          batch: batch,
        );
      }
    }
    await batch.commit();
  }

  Future<void> _updateStock({
    required String companyId,
    required String itemId,
    required String warehouseId,
    required double quantityChange,
    required String referenceType,
    required String referenceNumber,
    required DateTime date,
    required WriteBatch batch,
  }) async {
    final balanceRef = _getRef(companyId, 'stockBalances').doc('_');
    final balanceDoc = await balanceRef.get();
    double currentBalance = 0.0;

    if (balanceDoc.exists) {
      currentBalance = (balanceDoc.data() as Map<String, dynamic>)['quantity'] ?? 0.0;
    }

    double newBalance = currentBalance + quantityChange;
    batch.set(balanceRef, {
      'itemId': itemId,
      'warehouseId': warehouseId,
      'quantity': newBalance,
      'lastUpdated': Timestamp.fromDate(date),
    });

    final ledgerRef = _getRef(companyId, 'stockLedger').doc();
    final ledgerEntry = StockLedgerModel(
      id: '',
      companyId: companyId,
      itemId: itemId,
      warehouseId: warehouseId,
      date: date,
      referenceType: referenceType,
      referenceNumber: referenceNumber,
      quantityIn: quantityChange > 0 ? quantityChange : 0,
      quantityOut: quantityChange < 0 ? -quantityChange : 0,
      balanceAfter: newBalance,
    );
    batch.set(ledgerRef, ledgerEntry.toMap());
  }

  Stream<List<StockLedgerModel>> getStockLedger(String companyId, {String? itemId, String? warehouseId}) {
    Query query = _getRef(companyId, 'stockLedger').orderBy('date', descending: true);
    if (itemId != null) query = query.where('itemId', isEqualTo: itemId);
    if (warehouseId != null) query = query.where('warehouseId', isEqualTo: warehouseId);
    
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => StockLedgerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }
}
