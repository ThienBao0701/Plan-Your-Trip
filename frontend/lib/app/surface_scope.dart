import 'package:flutter/widgets.dart';

import 'app_surface.dart';

/// Makes the running [AppSurface] available to every route of a surface app.
///
/// Placed above the `MaterialApp`, so screens pushed from anywhere — the
/// sign-in screen a booking flow opens, for instance — still know which
/// application they belong to.
class SurfaceScope extends InheritedWidget {
  final AppSurface surface;

  const SurfaceScope({super.key, required this.surface, required super.child});

  /// The surface this context runs in, or null outside a surface app (an
  /// isolated widget test). Callers that route must treat null as "not
  /// configured" and fail closed, never as the traveller app.
  static AppSurface? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SurfaceScope>()?.surface;

  @override
  bool updateShouldNotify(SurfaceScope oldWidget) =>
      oldWidget.surface != surface;
}
