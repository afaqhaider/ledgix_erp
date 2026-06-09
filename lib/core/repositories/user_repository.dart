import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/models/app_user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> saveUser(AppUserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<List<AppUserModel>> getCompanyUsers(String companyId) async {
    final snapshot = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .get();

    // This is a bit tricky because AppUserModel comes from global collection.
    // We should probably fetch the global profiles for these members.
    List<AppUserModel> users = [];
    for (var doc in snapshot.docs) {
      final userDoc = await _firestore.collection('users').doc(doc.id).get();
      if (userDoc.exists) {
        users.add(AppUserModel.fromFirestore(userDoc));
      }
    }
    return users;
  }
}
