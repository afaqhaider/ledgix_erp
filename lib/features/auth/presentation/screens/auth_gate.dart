import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ledgixerp/features/auth/presentation/screens/login_screen.dart';
import 'package:ledgixerp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
import 'package:ledgixerp/features/company/presentation/screens/company_setup_screen.dart';

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

        // User is logged in, now check for company onboarding
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
              final String? companyId = userData['companyId'];

              if (companyId == null || companyId.isEmpty) {
                return const CompanySetupScreen();
              }

              return const DashboardScreen();
            }

            // Fallback if user doc doesn't exist yet (should be created on registration)
            return const Scaffold(
              body: Center(child: Text('Initializing user profile...')),
            );
          },
        );
      },
    );
  }
}
