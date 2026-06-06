import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branch_model.dart';

class BranchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getBranchRef(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('branches');
  }

  Stream<List<BranchModel>> getBranches(String companyId) {
    return _getBranchRef(companyId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BranchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addBranch(BranchModel branch) async {
    await _getBranchRef(branch.companyId).doc().set(branch.toMap());
  }

  Future<void> updateBranch(String companyId, BranchModel branch) async {
    await _getBranchRef(companyId).doc(branch.id).update(branch.toMap());
  }

  Future<void> deleteBranch(String companyId, String branchId) async {
    // Check if it's the main branch
    final doc = await _getBranchRef(companyId).doc(branchId).get();
    if (doc.exists && (doc.data() as Map<String, dynamic>)['isMainBranch'] == true) {
      throw Exception('Cannot delete the main branch.');
    }
    await _getBranchRef(companyId).doc(branchId).delete();
  }
}
