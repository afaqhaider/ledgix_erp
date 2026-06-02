import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';

class TrialBalanceScreen extends StatelessWidget {
  final AppUser user;
  const TrialBalanceScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trial Balance'),
      ),
      body: const Center(
        child: Text('Trial Balance module coming soon'),
      ),
    );
  }
}
