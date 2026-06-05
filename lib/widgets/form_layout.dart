import 'package:flutter/material.dart';

class FormLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const FormLayout({super.key, required this.child, this.maxWidth = 960});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
