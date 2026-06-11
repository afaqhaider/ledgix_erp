import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getAttendanceRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('attendance');
  }

  // --- Attendance ---

  Stream<List<AttendanceModel>> getAttendanceForDate(String companyId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _getAttendanceRef(companyId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> recordAttendance(AttendanceModel attendance) async {
    final ref = _getAttendanceRef(attendance.companyId).doc(attendance.id.isEmpty ? null : attendance.id);
    final toSave = attendance.copyWith(id: ref.id, updatedAt: DateTime.now());
    await ref.set(toSave.toMap(), SetOptions(merge: true));
  }

  Future<void> checkIn(String companyId, String employeeId, String employeeName) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final existing = await _getAttendanceRef(companyId)
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      if (data['checkIn'] != null) return; // Already checked in

      await doc.reference.update({
        'checkIn': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final newAttendance = AttendanceModel(
        id: '',
        companyId: companyId,
        employeeId: employeeId,
        employeeName: employeeName,
        date: today,
        checkIn: now,
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );
      await recordAttendance(newAttendance);
    }
  }

  Future<void> checkOut(String companyId, String employeeId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final existing = await _getAttendanceRef(companyId)
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'checkOut': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
