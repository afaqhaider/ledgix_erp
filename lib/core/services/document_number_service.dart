import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentNumberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getNextNumber(String companyId, String documentType) async {
    final docRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('sequences')
        .doc(documentType);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      int nextValue = 1;
      String prefix = documentType.substring(0, 3).toUpperCase();

      if (snapshot.exists) {
        nextValue = (snapshot.data()?['currentValue'] ?? 0) + 1;
        prefix = snapshot.data()?['prefix'] ?? prefix;
      }

      transaction.set(docRef, {
        'currentValue': nextValue,
        'prefix': prefix,
      }, SetOptions(merge: true));

      return "$prefix-${nextValue.toString().padLeft(5, '0')}";
    });
  }
}
