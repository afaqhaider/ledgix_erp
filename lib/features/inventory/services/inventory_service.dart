import 'package:cloud_firestore/cloud_firestore.dart';
import '../../settings/models/financial_settings_model.dart';
import '../../settings/services/financial_settings_service.dart';
import '../models/product_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

  CollectionReference _getProductsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('products');
  }

  Stream<List<ProductModel>> getProducts(String companyId) {
    return _getProductsRef(companyId).snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) => ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  Future<ProductModel> getProduct(String companyId, String productId) async {
    final doc = await _getProductsRef(companyId).doc(productId).get();
    if (!doc.exists) throw Exception('Product not found');
    return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> addProduct(ProductModel product) async {
    await _getProductsRef(product.companyId).doc().set(product.toMap());
  }

  Future<void> updateProduct(ProductModel product, {WriteBatch? batch}) async {
    final docRef = _getProductsRef(product.companyId).doc(product.id);
    if (batch != null) {
      batch.update(docRef, product.toMap());
    } else {
      await docRef.update(product.toMap());
    }
  }

  /// Records a purchase, updating stock quantity and valuation (FIFO or Weighted Average).
  Future<void> recordPurchase({
    required String companyId,
    required String productId,
    required double quantity,
    required double unitCost,
    String? purchaseId,
    WriteBatch? batch,
  }) async {
    final settings = await _settingsService.getSettings(companyId);
    final product = await getProduct(companyId, productId);

    double newStockQuantity = product.stockQuantity + quantity;
    double newCostPrice = product.costPrice;

    // Update Weighted Average Cost
    if (settings.inventoryValuationMethod ==
        InventoryValuationMethod.weightedAverage) {
      if (newStockQuantity > 0) {
        newCostPrice =
            ((product.stockQuantity * product.costPrice) +
                (quantity * unitCost)) /
            newStockQuantity;
      } else {
        newCostPrice = unitCost;
      }
    }

    // Add new batch for FIFO
    List<StockBatch> newBatches = List.from(product.stockBatches);
    newBatches.add(
      StockBatch(
        purchaseId: purchaseId,
        date: DateTime.now(),
        quantity: quantity,
        remainingQuantity: quantity,
        unitCost: unitCost,
      ),
    );

    final updatedProduct = product.copyWith(
      stockQuantity: newStockQuantity,
      costPrice: newCostPrice,
      stockBatches: newBatches,
    );

    await updateProduct(updatedProduct, batch: batch);
  }

  /// Records a sale and calculates COGS based on valuation method.
  /// Returns the total COGS for this sale.
  Future<double> recordSale({
    required String companyId,
    required String productId,
    required double quantity,
    WriteBatch? batch,
  }) async {
    final settings = await _settingsService.getSettings(companyId);
    final product = await getProduct(companyId, productId);

    if (product.type != ProductType.storable) return 0.0;

    double cogs = 0.0;
    double remainingToDeduct = quantity;
    List<StockBatch> updatedBatches = List.from(product.stockBatches);

    if (settings.inventoryValuationMethod == InventoryValuationMethod.fifo) {
      // FIFO: Consume batches from oldest to newest
      updatedBatches.sort((a, b) => a.date.compareTo(b.date));

      for (var batchItem in updatedBatches) {
        if (remainingToDeduct <= 0) break;

        if (batchItem.remainingQuantity > 0) {
          double deduct = remainingToDeduct > batchItem.remainingQuantity
              ? batchItem.remainingQuantity
              : remainingToDeduct;

          cogs += deduct * batchItem.unitCost;
          batchItem.remainingQuantity -= deduct;
          remainingToDeduct -= deduct;
        }
      }

      // Remove empty batches (optional, but keeps doc size small)
      updatedBatches.removeWhere((b) => b.remainingQuantity <= 0);
    } else {
      // Weighted Average: Use the current moving average cost
      cogs = quantity * product.costPrice;

      // Still need to update FIFO batches to stay in sync if user switches methods
      updatedBatches.sort((a, b) => a.date.compareTo(b.date));
      for (var batchItem in updatedBatches) {
        if (remainingToDeduct <= 0) break;
        if (batchItem.remainingQuantity > 0) {
          double deduct = remainingToDeduct > batchItem.remainingQuantity
              ? batchItem.remainingQuantity
              : remainingToDeduct;
          batchItem.remainingQuantity -= deduct;
          remainingToDeduct -= deduct;
        }
      }
      updatedBatches.removeWhere((b) => b.remainingQuantity <= 0);
    }

    final updatedProduct = product.copyWith(
      stockQuantity: product.stockQuantity - quantity,
      stockBatches: updatedBatches,
    );

    await updateProduct(updatedProduct, batch: batch);

    return cogs;
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
