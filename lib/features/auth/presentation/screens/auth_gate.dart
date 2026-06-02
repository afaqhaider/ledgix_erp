import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ledgixerp/features/auth/presentation/screens/login_screen.dart';
import 'package:ledgixerp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
import 'package:ledgixerp/features/company/presentation/screens/company_setup_screen.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/auth/user_role.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final appUser = AppUser.fromMap(userData, user.uid);

              if (appUser.companyId == null || appUser.companyId!.isEmpty) {
                return const CompanySetupScreen();
              }

              return DashboardScreen(user: appUser);
            }

            // Special case for manual admin testing: Bypass Firestore profile check
            // and grant full Owner permissions for this specific email.
            if (user.email == 'admin@admin.com') {
              final adminUser = AppUser(
                uid: user.uid,
                email: user.email!,
                fullName: 'System Admin',
                companyName: 'Test Company',
                companyId: 'test_company_id',
                role: UserRole.owner,
              );
              return DashboardScreen(user: adminUser);
            }

            return const Scaffold(
              body: Center(child: Text('Initializing user profile...')),
            );
          },
        );
      },
    );
  }
}
