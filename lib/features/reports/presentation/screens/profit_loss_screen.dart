import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';

class ProfitLossScreen extends StatelessWidget {
  final AppUser user;
  const ProfitLossScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss'),
      ),
      body: const Center(
        child: Text('Profit & Loss module coming soon'),
      ),
    );
  }
}
