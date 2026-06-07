import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../models/app_user_model.dart';
import '../screens/profile_screen.dart';
import 'package:ledgixerp/core/theme/theme_controller.dart';
import '../../../../features/auth/services/auth_service.dart';

class ProfileMenuButton extends StatelessWidget {
  final String uid;

  const ProfileMenuButton({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final authService = AuthService();

    return StreamBuilder<AppUserModel?>(
      stream: userService.getUserProfile(uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.displayName ?? 'User';
        final photoUrl = user?.photoUrl;

        return Row(
          children: [
            if (MediaQuery.of(context).size.width > 600)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              onSelected: (value) => _handleMenuSelection(context, value, authService),
              itemBuilder: (context) => [
                _buildMenuItem(
                  value: 'profile',
                  icon: Icons.person_outline_rounded,
                  label: 'My Profile',
                ),
                _buildMenuItem(
                  value: 'password',
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                ),
                _buildMenuItem(
                  value: 'switch',
                  icon: Icons.swap_horiz_rounded,
                  label: 'Switch Company',
                ),
                _buildMenuItem(
                  value: 'theme',
                  icon: ThemeController.isDark(context) ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: ThemeController.isDark(context) ? 'Light Mode' : 'Dark Mode',
                ),
                const PopupMenuDivider(),
                _buildMenuItem(
                  value: 'logout',
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: Colors.redAccent,
                ),
              ],
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          displayName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value, AuthService authService) {
    switch (value) {
      case 'profile':
        showDialog(
          context: context,
          builder: (context) => ProfileScreen(uid: uid),
        );
        break;
      case 'password':
        _showChangePasswordDialog(context, authService);
        break;
      case 'switch':
        _showSwitchCompanyDialog(context);
        break;
      case 'theme':
        ThemeController.toggle();
        break;
      case 'logout':
        authService.signOut();
        break;
    }
  }

  void _showChangePasswordDialog(BuildContext context, AuthService authService) {
    final email = authService.currentUser?.email;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Would you like to receive a password reset email?'),
            if (email != null) ...[
              const SizedBox(height: 8),
              Text(
                email,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (email != null) {
                try {
                  await authService.sendPasswordResetEmail(email);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  void _showSwitchCompanyDialog(BuildContext context) {
    final userService = UserService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Company'),
        content: SizedBox(
          width: 300,
          child: FutureBuilder<List<Map<String, String>>>(
            future: userService.getUserCompanies(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final companies = snapshot.data ?? [];
              if (companies.isEmpty) {
                return const Text('No other companies found.');
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: companies.map((company) {
                  return ListTile(
                    leading: const Icon(Icons.business_rounded),
                    title: Text(company['name'] ?? ''),
                    onTap: () async {
                      await userService.setDefaultCompany(uid, company['id']!);
                      if (context.mounted) {
                        Navigator.pop(context);
                        // Force a reload by navigating to home or using a provider
                        // For now, just show a message. In a real app, 
                        // you'd want to trigger a global state update.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Switched to ${company['name']}')),
                        );
                        // Force a full reload of the app gate
                        if (context.mounted) {
                          context.go('/');
                        }
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
