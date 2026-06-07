import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import '../models/app_user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<AppUserModel?> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppUserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) updates['displayName'] = displayName;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _firestore.collection('users').doc(uid).update(updates);
  }

  Future<void> setDefaultCompany(String uid, String companyId) async {
    await _firestore.collection('users').doc(uid).update({
      'defaultCompanyId': companyId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, String>>> getUserCompanies(String uid) async {
    // Collection group query to find all 'members' documents with this UID
    final snapshot = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    List<Map<String, String>> companies = [];
    for (var doc in snapshot.docs) {
      // The parent of 'members' is the company document
      final companyDoc = await doc.reference.parent.parent!.get();
      if (companyDoc.exists) {
        companies.add({
          'id': companyDoc.id,
          'name': companyDoc.data()?['tradeName'] ?? companyDoc.data()?['companyLegalName'] ?? 'Unknown Company',
        });
      }
    }
    return companies;
  }

  Future<String> uploadProfilePhoto(String uid, dynamic file, {String? fileName}) async {
    try {
      String extension = 'png';
      if (fileName != null && fileName.contains('.')) {
        extension = fileName.split('.').last.toLowerCase();
      }
      
      // Normalize common extensions to standard MIME types
      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }

      final storageRef = _storage.ref().child('users/$uid/profile/avatar.jpg');
      
      late final UploadTask uploadTask;
      if (kIsWeb) {
        if (file is! Uint8List) throw ArgumentError('Invalid file data for web');
        uploadTask = storageRef.putData(file, SettableMetadata(
          contentType: contentType,
          customMetadata: {'uid': uid, 'uploadedAt': DateTime.now().toIso8601String()},
        ));
      } else {
        if (file is! File) throw ArgumentError('Invalid file for mobile');
        uploadTask = storageRef.putFile(file, SettableMetadata(
          contentType: contentType,
          customMetadata: {'uid': uid, 'uploadedAt': DateTime.now().toIso8601String()},
        ));
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('UserService.uploadProfilePhoto error: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission Denied: You do not have permission to upload to this location.');
      }
      throw Exception('Failed to upload profile photo: ${e.toString()}');
    }
  }
}

class CompanyUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CompanyMemberModel>> getCompanyMembers(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CompanyMemberModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateMemberRole(String companyId, String uid, UserRole role) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .doc(uid)
        .update({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMemberStatus(String companyId, String uid, UserStatus status) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .doc(uid)
        .update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> inviteUser({
    required String companyId,
    required String email,
    required String displayName,
    required UserRole role,
    required String invitedByUserId,
  }) async {
    // Check if user already exists as a member
    final existing = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .where('email', isEqualTo: email)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('User is already a member of this company');
    }

    // In a real app, this might trigger a Cloud Function to send an email
    // For now, we'll just create the member record with 'invited' status
    final docRef = _firestore.collection('companies').doc(companyId).collection('members').doc();
    
    final newMember = CompanyMemberModel(
      uid: docRef.id,
      email: email,
      displayName: displayName,
      role: role,
      status: UserStatus.invited,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(newMember.toMap());
  }
}
