import 'package:flutter/material.dart';

/// Helper utilitário para decisões de layout responsivo.
/// Breakpoints:
///   - Mobile:  < 600px
///   - Tablet:  600px – 899px
///   - Desktop: >= 900px
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Retorna um valor baseado no breakpoint atual.
  static T value<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }

  /// Número ideal de colunas de grid baseado na largura disponível.
  static int gridColumns(BuildContext context, {double minItemWidth = 160}) {
    final width = MediaQuery.of(context).size.width;
    return (width / minItemWidth).floor().clamp(1, 6);
  }
}
