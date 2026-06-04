import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../accounting/chart_of_accounts/account_service.dart';
import '../../settings/services/financial_settings_service.dart';
import '../models/company_model.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> setupCompany(CompanyModel company) async {
    final companyRef = _firestore.collection('companies').doc();
    final companyId = companyRef.id;

    debugPrint('CompanyService: [1/4] Creating company doc: $companyId');
    try {
      await companyRef.set(company.toMap());
    } catch (e) {
      debugPrint('CompanyService: FAILED at step 1: $e');
      rethrow;
    }

    debugPrint('CompanyService: [2/4] Initializing financial settings...');
    try {
      await FinancialSettingsService().getSettings(companyId);
    } catch (e) {
      debugPrint('CompanyService: Warning at step 2 (Settings): $e');
      // We don't rethrow here so the user isn't blocked if just settings fail
    }

    debugPrint('CompanyService: [3/4] Seeding default accounts...');
    try {
      await AccountService().seedDefaultAccounts(companyId);
    } catch (e) {
      debugPrint('CompanyService: Warning at step 3 (COA): $e');
    }

    debugPrint(
      'CompanyService: [4/4] Updating user profile: ${company.createdByUserId}',
    );
    try {
      final userRef = _firestore
          .collection('users')
          .doc(company.createdByUserId);
      await userRef.set({
        'companyId': companyId,
        'companyName': company.tradeName,
        'role': 'owner',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CompanyService: FAILED at step 4 (User Update): $e');
      rethrow;
    }

    debugPrint('CompanyService: SETUP SUCCESSFUL');
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
