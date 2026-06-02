import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';

class BalanceSheetScreen extends StatelessWidget {
  final AppUser user;
  const BalanceSheetScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Sheet'),
      ),
      body: const Center(
        child: Text('Balance Sheet module coming soon'),
      ),
    );
  }
}
