import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgixerp/features/dashboard/presentation/screens/dashboard_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    // Future routes will be added here
  ],
);
