import 'package:flutter/material.dart';

/// Shared sizing rules for Paoly's phone-first screens.
///
/// Content stays comfortably readable on tablets and desktop, while narrow
/// phones retain enough horizontal room for Thai and currency labels.
class ResponsiveLayout {
  static const double contentMaxWidth = 760;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = switch (width) {
      < 360 => 16.0,
      < 600 => 20.0,
      < 1000 => 28.0,
      _ => 36.0,
    };
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  static Widget constrain(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: contentMaxWidth),
      child: child,
    ),
  );
}
