import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ledgixerp/features/auth/presentation/screens/login_screen.dart';
import 'package:ledgixerp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
import 'package:ledgixerp/features/company/presentation/screens/company_setup_screen.dart';
import 'package:ledgixerp/core/auth/app_user.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isCreatingProfile = false;
  String? _creationError;

  Future<void> _ensureUserProfile(User user) async {
    if (_isCreatingProfile) return;

    setState(() {
      _isCreatingProfile = true;
      _creationError = null;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await docRef.get().timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        debugPrint('AuthGate: User profile missing, creating for ${user.uid}');
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'fullName':
              user.displayName ?? user.email?.split('@').first ?? 'User',
          'companyId': null,
          'companyName': '',
          'role': 'owner',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('AuthGate: Error ensuring user profile: $e');
      if (mounted) {
        setState(() {
          _creationError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold(message: 'Connecting to Auth...');
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
            if (userSnapshot.hasError) {
              return _ErrorScaffold(
                message: 'Firestore Error: ${userSnapshot.error}',
                onRetry: () => setState(() {}),
              );
            }

            if (userSnapshot.connectionState == ConnectionState.waiting ||
                _isCreatingProfile) {
              return const _LoadingScaffold(message: 'Loading Profile...');
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final appUser = AppUser.fromMap(userData, user.uid);

              // DEBUG: Print user state
              debugPrint(
                'AuthGate: Loaded profile for ${appUser.fullName}. CompanyId: ${appUser.companyId}',
              );

              if (appUser.companyId == null || appUser.companyId!.isEmpty) {
                debugPrint(
                  'AuthGate: Redirecting to CompanySetup (Missing CompanyId)',
                );
                return CompanySetupScreen(user: appUser);
              }

              debugPrint('AuthGate: Redirecting to Dashboard');
              return DashboardScreen(user: appUser);
            }

            // Document doesn't exist and we aren't currently creating it
            if (_creationError != null) {
              return _ErrorScaffold(
                message: 'Profile Creation Failed: $_creationError',
                onRetry: () => _ensureUserProfile(user),
              );
            }

            // Trigger profile creation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _ensureUserProfile(user);
            });

            return const _LoadingScaffold(message: 'Initializing Profile...');
          },
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  final String message;
  const _LoadingScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => AuthService().signOut(),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
