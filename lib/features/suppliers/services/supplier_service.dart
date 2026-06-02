import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/suppliers/models/supplier_model.dart';

class SupplierService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getSuppliersRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('suppliers');
  }

  Stream<List<SupplierModel>> getSuppliers(String companyId) {
    return _getSuppliersRef(companyId).orderBy('supplierCode').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return SupplierModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<String> generateNextSupplierCode(String companyId) async {
    final snapshot = await _getSuppliersRef(
      companyId,
    ).orderBy('supplierCode', descending: true).limit(1).get();

    if (snapshot.docs.isEmpty) {
      return 'SUP-0001';
    }

    final lastCode = snapshot.docs.first.get('supplierCode') as String;
    final numberMatch = RegExp(r'\d+').firstMatch(lastCode);
    if (numberMatch != null) {
      final lastNumber = int.parse(numberMatch.group(0)!);
      final nextNumber = lastNumber + 1;
      return 'SUP-${nextNumber.toString().padLeft(4, '0')}';
    }

    return 'SUP-0001';
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    await _getSuppliersRef(supplier.companyId).doc().set(supplier.toMap());
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    await _getSuppliersRef(
      supplier.companyId,
    ).doc(supplier.id).update(supplier.toMap());
  }

  Future<void> deleteSupplier(String companyId, String supplierId) async {
    // Check for transactions
    final paymentSnapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierPayments')
        .where('supplierId', isEqualTo: supplierId)
        .limit(1)
        .get();

    if (paymentSnapshot.docs.isNotEmpty) {
      throw Exception('Cannot delete supplier with existing payments.');
    }

    // Also check for purchase orders if they exist
    final poSnapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('purchaseOrders')
        .where('supplierId', isEqualTo: supplierId)
        .limit(1)
        .get();

    if (poSnapshot.docs.isNotEmpty) {
      throw Exception('Cannot delete supplier with existing purchase orders.');
    }

    await _getSuppliersRef(companyId).doc(supplierId).delete();
  }
}
