import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';

class GeneralLedgerScreen extends StatelessWidget {
  final AppUser user;
  const GeneralLedgerScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('General Ledger'),
      ),
      body: const Center(
        child: Text('General Ledger module coming soon'),
      ),
    );
  }
}
