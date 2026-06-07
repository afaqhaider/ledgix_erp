import 'package:ledgixerp/core/auth/user_role.dart';
import '../../features/users/models/app_user_model.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String? companyId;
  final String companyName;
  final UserRole role;
  final UserStatus status;
  final UserType userType;
  final List<String> permissions;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    this.companyId,
    required this.companyName,
    required this.role,
    this.status = UserStatus.active,
    this.userType = UserType.internal,
    this.permissions = const [],
  });

  factory AppUser.fromModels({
    required AppUserModel globalProfile,
    CompanyMemberModel? membership,
    String? companyName,
  }) {
    return AppUser(
      uid: globalProfile.uid,
      email: globalProfile.email,
      fullName: globalProfile.displayName,
      companyId: globalProfile.defaultCompanyId,
      role: membership?.role ?? UserRole.employee,
      status: membership?.status ?? UserStatus.active,
      userType: membership?.userType ?? UserType.internal,
      permissions: membership?.permissions ?? [],
      companyName: companyName ?? '',
    );
  }

  // Legacy factory for compatibility during migration if needed
  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['displayName'] ?? map['fullName'] ?? '',
      companyId: map['companyId'] ?? map['defaultCompanyId'],
      companyName: map['companyName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'employee'),
        orElse: () => UserRole.employee,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'active'),
        orElse: () => UserStatus.active,
      ),
      userType: UserType.values.firstWhere(
        (e) => e.name == (map['userType'] ?? 'internal'),
        orElse: () => UserType.internal,
      ),
      permissions: List<String>.from(map['permissions'] ?? []),
    );
  }
}
