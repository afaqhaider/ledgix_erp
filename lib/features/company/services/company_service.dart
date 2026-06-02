import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setupCompany({
    required String uid,
    required String legalName,
    required String tradeName,
    required String country,
    required String currency,
    String? trn,
    required int financialYearStartMonth,
  }) async {
    final batch = _firestore.batch();
    
    // 1. Create new company document
    final companyRef = _firestore.collection('companies').doc();
    final companyId = companyRef.id;

    final company = CompanyModel(
      id: companyId,
      legalName: legalName,
      tradeName: tradeName,
      country: country,
      currency: currency,
      trn: trn,
      financialYearStartMonth: financialYearStartMonth,
      ownerId: uid,
      createdAt: DateTime.now(),
    );

    batch.set(companyRef, company.toMap());

    // 2. Update user document with companyId
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {
      'companyId': companyId,
      'role': 'owner',
    });

    await batch.commit();
  }

  Future<DocumentSnapshot> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }
}
