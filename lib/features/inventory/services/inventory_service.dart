import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getProductsRef(String companyId) {
    return _firestore.collection('companies').doc(companyId).collection('products');
  }

  Stream<List<ProductModel>> getProducts(String companyId) {
    return _getProductsRef(companyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addProduct(ProductModel product) async {
    await _getProductsRef(product.companyId).doc().set(product.toMap());
  }

  Future<void> updateStock(String companyId, String productId, double delta) async {
    await _getProductsRef(companyId).doc(productId).update({
      'stockQuantity': FieldValue.increment(delta),
    });
  }

  Future<void> recordStockAdjustment({
    required String companyId,
    required String productId,
    required double quantity,
    required String reason,
    required String userId,
  }) async {
    final batch = _firestore.batch();
    
    final productRef = _getProductsRef(companyId).doc(productId);
    batch.update(productRef, {'stockQuantity': FieldValue.increment(quantity)});
    
    final adjustmentRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('inventoryAdjustments')
        .doc();
    
    batch.set(adjustmentRef, {
      'id': adjustmentRef.id,
      'productId': productId,
      'quantity': quantity,
      'reason': reason,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
