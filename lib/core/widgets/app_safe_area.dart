import 'package:flutter/material.dart';

class AppSafeArea extends StatelessWidget {
  final Widget child;

  const AppSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: true,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: child,
    );
  }
}
