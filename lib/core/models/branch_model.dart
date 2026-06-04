import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String companyId;
  final String name;
  final String? address;
  final String? phone;
  final bool isMainBranch;
  final DateTime createdAt;

  BranchModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.address,
    this.phone,
    required this.isMainBranch,
    required this.createdAt,
  });

  factory BranchModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BranchModel(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'],
      phone: data['phone'],
      isMainBranch: data['isMainBranch'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'name': name,
      'address': address,
      'phone': phone,
      'isMainBranch': isMainBranch,
      'createdAt': createdAt,
    };
  }
}
