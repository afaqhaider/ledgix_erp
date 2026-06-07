import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgixerp/core/auth/user_role.dart';

enum UserStatus { invited, active, disabled }
enum UserType { internal, customerPortal, supplierPortal }

/// Global User Profile (stored in /users/{uid})
class AppUserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? defaultCompanyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.defaultCompanyId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'defaultCompanyId': defaultCompanyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map, String id) {
    return AppUserModel(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      defaultCompanyId: map['defaultCompanyId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Company-specific Membership (stored in /companies/{companyId}/members/{uid})
class CompanyMemberModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final UserStatus status;
  final UserType userType;
  final String? customerId;
  final String? supplierId;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyMemberModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.status = UserStatus.active,
    this.userType = UserType.internal,
    this.customerId,
    this.supplierId,
    this.permissions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'status': status.name,
      'userType': userType.name,
      'customerId': customerId,
      'supplierId': supplierId,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CompanyMemberModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyMemberModel(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.employee,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      userType: UserType.values.firstWhere(
        (e) => e.name == map['userType'],
        orElse: () => UserType.internal,
      ),
      customerId: map['customerId'],
      supplierId: map['supplierId'],
      permissions: List<String>.from(map['permissions'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
