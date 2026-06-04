import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/suppliers/models/bill_model.dart';
import '../../settings/services/financial_settings_service.dart';

class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _settingsService = FinancialSettingsService();

  CollectionReference _getBillsRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('supplierBills');
  }

  Stream<List<BillModel>> getBills(String companyId) {
    return _getBillsRef(
      companyId,
    ).orderBy('billDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BillModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<String> generateNextBillNumber(String companyId) async {
    return await _settingsService.previewNextDocumentNumber(companyId, 'bill');
  }

  Future<void> addBill(BillModel bill) async {
    if (await _settingsService.isPeriodLocked(bill.companyId, bill.billDate)) {
      throw Exception('Accounting period for this date is locked.');
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Generate and increment within transaction
      final actualBillNumber = await _settingsService.getNextDocumentNumberAndIncrement(
        bill.companyId,
        'bill',
        transaction: transaction,
      );

      final docRef = _getBillsRef(bill.companyId).doc();
      final finalBill = bill.copyWith(
        id: docRef.id,
        billNumber: actualBillNumber,
      );

      // 2. Save bill
      transaction.set(docRef, finalBill.toMap());
    });
  }

  Future<void> updateBillStatus(
    String companyId,
    String billId,
    BillStatus status,
  ) async {
    await _getBillsRef(companyId).doc(billId).update({'status': status.name});
  }

  Future<void> deleteBill(String companyId, String billId) async {
    await _getBillsRef(companyId).doc(billId).delete();
  }
}
