import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? role; // e.g., 'admin', 'accountant', 'sales'
  final List<String> companyIds;
  final List<String> branchIds;
  final Map<String, dynamic>? customPermissions;
  final bool isActive;
  final DateTime createdAt;

  AppUserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.role,
    required this.companyIds,
    required this.branchIds,
    this.customPermissions,
    required this.isActive,
    required this.createdAt,
  });

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: data['role'],
      companyIds: List<String>.from(data['companyIds'] ?? []),
      branchIds: List<String>.from(data['branchIds'] ?? []),
      customPermissions: data['customPermissions'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'companyIds': companyIds,
      'branchIds': branchIds,
      'customPermissions': customPermissions,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
