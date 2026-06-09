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
    return _getRef(companyId, 'items').snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => InventoryItemModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  Future<InventoryItemModel> getItem(String companyId, String itemId) async {
    final doc = await _getRef(companyId, 'items').doc(itemId).get();
    if (!doc.exists) throw Exception('Inventory item not found');
    return InventoryItemModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  Future<void> addItem(InventoryItemModel item) async {
    await _getRef(
      item.companyId,
      'items',
    ).doc(item.id.isEmpty ? null : item.id).set(item.toMap());
  }

  Future<void> updateItem(InventoryItemModel item) async {
    // PROTECT stockQuantity and costPrice: Do not allow direct updates.
    final Map<String, dynamic> data = item.toMap();
    data.remove('stockQuantity');
    data.remove('costPrice');
    await _getRef(item.companyId, 'items').doc(item.id).update(data);
  }

  Future<void> deleteItem(String companyId, String itemId) async {
    await _getRef(companyId, 'items').doc(itemId).delete();
  }

  // Categories
  Stream<List<InventoryCategoryModel>> getCategories(String companyId) {
    return _getRef(companyId, 'itemCategories').snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => InventoryCategoryModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  Future<void> addCategory(InventoryCategoryModel category) async {
    await _getRef(
      category.companyId,
      'itemCategories',
    ).doc().set(category.toMap());
  }

  // Warehouses
  Stream<List<WarehouseModel>> getWarehouses(String companyId) {
    return _getRef(companyId, 'warehouses').snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => WarehouseModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  Future<void> addWarehouse(WarehouseModel warehouse) async {
    await _getRef(
      warehouse.companyId,
      'warehouses',
    ).doc().set(warehouse.toMap());
  }

  // UOM
  Stream<List<UomModel>> getUoms(String companyId) {
    return _getRef(companyId, 'unitsOfMeasure').snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) =>
                UomModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList(),
    );
  }

  Future<void> addUom(UomModel uom) async {
    await _getRef(uom.companyId, 'unitsOfMeasure').doc().set(uom.toMap());
  }

  // UOM Conversions
  Stream<List<UomConversionModel>> getUomConversions(String companyId) {
    return _getRef(companyId, 'uomConversions').snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => UomConversionModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  Future<void> addUomConversion(UomConversionModel conversion) async {
    await _getRef(
      conversion.companyId,
      'uomConversions',
    ).doc().set(conversion.toMap());
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
