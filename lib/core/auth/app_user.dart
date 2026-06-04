import 'package:ledgixerp/core/auth/user_role.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String companyName;
  final String? companyId;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.companyName,
    this.companyId,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      companyName: map['companyName'] ?? '',
      companyId: map['companyId'],
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'dataEntry'),
        orElse: () => UserRole.dataEntry,
      ),
    );
  }
}
