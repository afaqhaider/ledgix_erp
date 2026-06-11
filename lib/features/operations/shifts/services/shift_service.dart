import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';

class ShiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getShiftRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('shifts');
  }

  Stream<List<ShiftModel>> getShifts(String companyId) {
    return _getShiftRef(companyId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShiftModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addShift(ShiftModel shift) async {
    final docRef = _getShiftRef(shift.companyId).doc();
    await docRef.set(shift.toMap()..['id'] = docRef.id);
  }

  Future<void> updateShift(ShiftModel shift) async {
    await _getShiftRef(shift.companyId).doc(shift.id).update(shift.toMap());
  }

  Future<void> deleteShift(String companyId, String shiftId) async {
    await _getShiftRef(companyId).doc(shiftId).delete();
  }
}
