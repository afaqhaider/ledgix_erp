import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/models/company_model.dart';
import 'package:ledgixerp/core/models/branch_model.dart';

class CompanyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<CompanyModel?> getCompany(String id) async {
    final doc = await _firestore.collection('companies').doc(id).get();
    if (doc.exists) {
      return CompanyModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateCompany(CompanyModel company) async {
    await _firestore
        .collection('companies')
        .doc(company.id)
        .update(company.toFirestore());
  }

  Future<List<BranchModel>> getBranches(String companyId) async {
    final snapshot = await _firestore
        .collection('branches')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snapshot.docs.map((doc) => BranchModel.fromFirestore(doc)).toList();
  }
}
