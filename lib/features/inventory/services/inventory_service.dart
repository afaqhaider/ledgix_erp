import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_models.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getRef(String companyId, String collection) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection(collection);
  }

  // Items
  Stream<List<InventoryItemModel>> getInventoryItems(String companyId) {
    return _getRef(companyId, 'inventoryItems').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => InventoryItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  Future<InventoryItemModel> getItem(String companyId, String itemId) async {
    final doc = await _getRef(companyId, 'inventoryItems').doc(itemId).get();
    if (!doc.exists) throw Exception('Inventory item not found');
    return InventoryItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> addItem(InventoryItemModel item) async {
    await _getRef(item.companyId, 'inventoryItems').doc(item.id.isEmpty ? null : item.id).set(item.toMap());
  }

  Future<void> updateItem(InventoryItemModel item) async {
    await _getRef(item.companyId, 'inventoryItems').doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String companyId, String itemId) async {
    await _getRef(companyId, 'inventoryItems').doc(itemId).delete();
  }

  // Categories
  Stream<List<InventoryCategoryModel>> getCategories(String companyId) {
    return _getRef(companyId, 'inventoryCategories').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => InventoryCategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  Future<void> addCategory(InventoryCategoryModel category) async {
    await _getRef(category.companyId, 'inventoryCategories').doc().set(category.toMap());
  }

  // Warehouses
  Stream<List<WarehouseModel>> getWarehouses(String companyId) {
    return _getRef(companyId, 'warehouses').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => WarehouseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  Future<void> addWarehouse(WarehouseModel warehouse) async {
    await _getRef(warehouse.companyId, 'warehouses').doc().set(warehouse.toMap());
  }

  // UOM
  Stream<List<UomModel>> getUoms(String companyId) {
    return _getRef(companyId, 'uoms').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => UomModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  Future<void> addUom(UomModel uom) async {
    await _getRef(uom.companyId, 'uoms').doc().set(uom.toMap());
  }

  // UOM Conversions
  Stream<List<UomConversionModel>> getUomConversions(String companyId) {
    return _getRef(companyId, 'uomConversions').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => UomConversionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  Future<void> addUomConversion(UomConversionModel conversion) async {
    await _getRef(conversion.companyId, 'uomConversions').doc().set(conversion.toMap());
  }

  /// Records a sale.
  Future<double> recordSale({
    required String companyId,
    required String productId,
    required double quantity,
    WriteBatch? batch,
  }) async {
    // This is a stub for the required method.
    // In a real implementation, this would update stock balances and return COGS.
    return 0.0; 
  }

  /// Records a purchase.
  Future<void> recordPurchase({
    required String companyId,
    required String productId,
    required double quantity,
    required double unitCost,
    String? purchaseId,
    WriteBatch? batch,
  }) async {
    // This is a stub for the required method.
    // In a real implementation, this would update stock balances and unit costs.
  }
}
