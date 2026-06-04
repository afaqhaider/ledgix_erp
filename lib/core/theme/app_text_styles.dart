import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle h1(BuildContext context) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle h2(BuildContext context) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle title(BuildContext context) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle body(BuildContext context) => TextStyle(
    fontSize: 14,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
  );

  static TextStyle label(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
  );
}
