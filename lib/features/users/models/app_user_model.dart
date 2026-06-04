import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/auth/user_role.dart';

enum UserStatus { active, invited, disabled }

class CompanyUserModel {
  final String uid;
  final String companyId;
  final String fullName;
  final String email;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? invitedAt;
  final String? invitedByUserId;

  CompanyUserModel({
    required this.uid,
    required this.companyId,
    required this.fullName,
    required this.email,
    required this.role,
    this.status = UserStatus.active,
    required this.createdAt,
    this.invitedAt,
    this.invitedByUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'companyId': companyId,
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'status': status.name,
      'createdAt': createdAt,
      'invitedAt': invitedAt,
      'invitedByUserId': invitedByUserId,
    };
  }

  factory CompanyUserModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyUserModel(
      uid: id,
      companyId: map['companyId'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.dataEntry,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      invitedAt: (map['invitedAt'] as Timestamp?)?.toDate(),
      invitedByUserId: map['invitedByUserId'],
    );
  }
}
