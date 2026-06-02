import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setupCompany({
    required String uid,
    required String companyLegalName,
    required String tradeName,
    required String country,
    required String currency,
    String? trnVatNumber,
    required int financialYearStartMonth,
    String? companyLogoUrl,
    String? primaryBrandColor,
  }) async {
    final batch = _firestore.batch();
    
    // 1. Create new company document
    final companyRef = _firestore.collection('companies').doc();
    final companyId = companyRef.id;

    final company = CompanyModel(
      id: companyId,
      companyLegalName: companyLegalName,
      tradeName: tradeName,
      country: country,
      currency: currency,
      trnVatNumber: trnVatNumber,
      financialYearStartMonth: financialYearStartMonth,
      companyLogoUrl: companyLogoUrl,
      primaryBrandColor: primaryBrandColor,
      createdAt: DateTime.now(),
      createdByUserId: uid,
    );

    batch.set(companyRef, company.toMap());

    // 2. Update user document with companyId and set role as owner
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {
      'companyId': companyId,
      'role': 'owner',
    });

    await batch.commit();
  }

  Future<CompanyModel?> getCompany(String companyId) async {
    final doc = await _firestore.collection('companies').doc(companyId).get();
    if (doc.exists) {
      return CompanyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }
}
