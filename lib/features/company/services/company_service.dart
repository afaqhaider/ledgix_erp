import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/company_model.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> setupCompany(CompanyModel company) async {
    final batch = _firestore.batch();

    final companyRef = _firestore.collection('companies').doc();
    final companyId = companyRef.id;

    batch.set(companyRef, company.toMap());

    // Update user's companyId and role
    final userRef = _firestore.collection('users').doc(company.createdByUserId);
    batch.update(userRef, {'companyId': companyId, 'role': 'owner'});

    await batch.commit();
    return companyId;
  }

  Future<void> updateCompany(CompanyModel company) async {
    await _firestore
        .collection('companies')
        .doc(company.id)
        .update(company.toMap());
  }

  Future<String?> uploadLogo(String companyId, dynamic file) async {
    try {
      final storageRef = _storage.ref().child('companies/$companyId/logo.png');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(file as Uint8List);
      } else {
        uploadTask = storageRef.putFile(file as File);
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading logo: $e');
      return null;
    }
  }

  Stream<CompanyModel?> getCompany(String companyId) {
    return _firestore.collection('companies').doc(companyId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return CompanyModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }
}
