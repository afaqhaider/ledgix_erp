import 'package:flutter/material.dart';
import 'package:ledgixerp/theme/app_theme.dart';
import 'package:ledgixerp/config/app_router.dart';

class LedGixERPApp extends StatelessWidget {
  const LedGixERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LedGix ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
