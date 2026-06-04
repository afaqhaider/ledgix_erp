import 'package:flutter/material.dart';
import '../../../../core/auth/app_user.dart';

class ShiftsScreen extends StatelessWidget {
  final AppUser user;
  const ShiftsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shifts')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_time, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Shifts Module',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage staff shifts and attendance.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.timer_outlined),
      ),
    );
  }
}
