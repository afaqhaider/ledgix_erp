import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgixerp/features/auth/presentation/screens/auth_gate.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  routes: [GoRoute(path: '/', builder: (context, state) => const AuthGate())],
);
