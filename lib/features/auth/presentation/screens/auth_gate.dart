import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ledgixerp/features/auth/presentation/screens/login_screen.dart';
import 'package:ledgixerp/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
import 'package:ledgixerp/features/company/presentation/screens/company_setup_screen.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/users/models/app_user_model.dart';

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
        debugPrint('AuthGate: Global user profile missing, creating for ${user.uid}');
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName':
              user.displayName ?? user.email?.split('@').first ?? 'User',
          'defaultCompanyId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('AuthGate: Error ensuring global profile: $e');
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
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold(message: 'Connecting to Auth...');
        }

        final user = authSnapshot.data;
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
                message: 'Firestore Error (Global Profile): ${userSnapshot.error}',
                onRetry: () => setState(() {}),
              );
            }

            if (userSnapshot.connectionState == ConnectionState.waiting ||
                _isCreatingProfile) {
              return const _LoadingScaffold(message: 'Loading Global Profile...');
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final globalData = userSnapshot.data!.data() as Map<String, dynamic>;
              final globalProfile = AppUserModel.fromMap(globalData, user.uid);

              if (globalProfile.defaultCompanyId == null || globalProfile.defaultCompanyId!.isEmpty) {
                // Return a temporary AppUser for CompanySetupScreen
                final tempUser = AppUser.fromModels(globalProfile: globalProfile);
                return CompanySetupScreen(user: tempUser);
              }

              // Now fetch membership and company info
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('companies')
                    .doc(globalProfile.defaultCompanyId)
                    .collection('members')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, memberSnapshot) {
                  if (memberSnapshot.hasError) {
                    final error = memberSnapshot.error.toString();
                    debugPrint('AuthGate: Member Stream Error: $error');
                    if (error.contains('permission-denied')) {
                      return _AccessDeniedScaffold(
                        companyId: globalProfile.defaultCompanyId!,
                        uid: user.uid,
                        onRetry: () => setState(() {}),
                      );
                    }
                    return _ErrorScaffold(
                      message: 'Membership Error: $error',
                      onRetry: () => setState(() {}),
                    );
                  }

                  if (memberSnapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingScaffold(message: 'Verifying Membership...');
                  }

                  if (!memberSnapshot.hasData || !memberSnapshot.data!.exists) {
                    debugPrint('AuthGate: Membership missing for company ${globalProfile.defaultCompanyId}');
                    // Fallback to setup if membership doesn't exist for some reason
                    final tempUser = AppUser.fromModels(globalProfile: globalProfile);
                    return CompanySetupScreen(user: tempUser);
                  }

                  final memberData = memberSnapshot.data!.data() as Map<String, dynamic>;
                  final membership = CompanyMemberModel.fromMap(memberData, user.uid);

                  if (membership.status != UserStatus.active) {
                    return _InactiveMemberScaffold(status: membership.status);
                  }

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('companies')
                        .doc(globalProfile.defaultCompanyId)
                        .snapshots(),
                    builder: (context, companySnapshot) {
                      if (companySnapshot.hasError) {
                         final error = companySnapshot.error.toString();
                         debugPrint('AuthGate: Company Stream Error: $error');
                         // If we can't read the company doc, but we ARE a member, something is wrong with rules
                         return _ErrorScaffold(
                           message: 'Company Access Error: $error',
                           onRetry: () => setState(() {}),
                         );
                      }

                      if (companySnapshot.connectionState == ConnectionState.waiting) {
                        return const _LoadingScaffold(message: 'Loading Company...');
                      }

                      final companyName = companySnapshot.hasData && companySnapshot.data!.exists
                          ? (companySnapshot.data!.data() as Map<String, dynamic>)['tradeName'] ?? ''
                          : 'Unknown Company';

                      final appUser = AppUser.fromModels(
                        globalProfile: globalProfile,
                        membership: membership,
                        companyName: companyName,
                      );

                      return DashboardScreen(user: appUser);
                    },
                  );
                },
              );
            }

            // Trigger profile creation if it doesn't exist
            if (_creationError != null) {
              return _ErrorScaffold(
                message: 'Profile Creation Failed: $_creationError',
                onRetry: () => _ensureUserProfile(user),
              );
            }

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
              const SizedBox(height: 12),
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

class _AccessDeniedScaffold extends StatelessWidget {
  final String companyId;
  final String uid;
  final VoidCallback onRetry;

  const _AccessDeniedScaffold({
    required this.companyId,
    required this.uid,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_outlined, color: Colors.orange, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Access Restricted',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'You are trying to access a company where you are not yet a confirmed member, or your membership status is invalid.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Check Again'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Clear default company and go back to setup
                  FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'defaultCompanyId': null,
                  });
                },
                child: const Text('Start New Company Setup'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => AuthService().signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InactiveMemberScaffold extends StatelessWidget {
  final UserStatus status;
  const _InactiveMemberScaffold({required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == UserStatus.invited ? Icons.mail_outline : Icons.block,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              status == UserStatus.invited ? 'Invitation Pending' : 'Account Disabled',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                status == UserStatus.invited
                    ? 'You have been invited to join this company. Please wait for an administrator to activate your account.'
                    : 'Your account in this company has been disabled. Please contact your administrator.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => AuthService().signOut(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

