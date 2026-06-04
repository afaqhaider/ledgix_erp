import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/features/approvals/presentation/screens/approval_center_screen.dart';

class ApprovalsScreen extends StatelessWidget {
  final AppUser user;
  const ApprovalsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ApprovalCenterScreen(user: user);
  }
}
