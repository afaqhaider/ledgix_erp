import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import '../models/app_user_model.dart';

class CompanyUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getUsersRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('users');
  }

  Stream<List<CompanyUserModel>> getCompanyUsers(String companyId) {
    return _getUsersRef(companyId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CompanyUserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> inviteUser({
    required String companyId,
    required String email,
    required String fullName,
    required UserRole role,
    required String invitedByUserId,
  }) async {
    // In a real app, this would trigger a Firebase Function to send an email
    // and potentially create a placeholder auth user or an invite record.
    // For this module, we'll create the record in the company's users subcollection.

    final userRef = _getUsersRef(
      companyId,
    ).doc(); // Temporary ID or based on email hash

    final newUser = CompanyUserModel(
      uid: userRef.id,
      companyId: companyId,
      fullName: fullName,
      email: email,
      role: role,
      status: UserStatus.invited,
      createdAt: DateTime.now(),
      invitedAt: DateTime.now(),
      invitedByUserId: invitedByUserId,
    );

    await userRef.set(newUser.toMap());

    // Also sync to main users collection if necessary (though usually main auth handles this on first login)
    // await _firestore.collection('users').doc(userRef.id).set(newUser.toMap());
  }

  Future<void> updateUserRole(
    String companyId,
    String userId,
    UserRole role,
  ) async {
    final batch = _firestore.batch();

    // Update in company subcollection
    batch.update(_getUsersRef(companyId).doc(userId), {'role': role.name});

    // Update in global users collection (if the user exists there)
    batch.update(_firestore.collection('users').doc(userId), {
      'role': role.name,
    });

    await batch.commit();
  }

  Future<void> updateUserStatus(
    String companyId,
    String userId,
    UserStatus status,
  ) async {
    final batch = _firestore.batch();

    batch.update(_getUsersRef(companyId).doc(userId), {'status': status.name});
    batch.update(_firestore.collection('users').doc(userId), {
      'status': status.name,
    });

    await batch.commit();
  }
}
