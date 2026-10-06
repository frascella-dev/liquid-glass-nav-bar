import 'package:flutter/widgets.dart';

/// What the platform says about glass that Flutter does not report itself.
///
/// Put one above the navigation, reading the facts once at start (Android's API level,
/// iOS's Reduce Transparency), for example with `device_info_plus` or a method channel.
/// Without a policy the bar assumes a platform that blurs and no reduced transparency.
///
/// What Flutter does report (high contrast, Android's "Remove animations", iOS's Reduce
/// Motion) the bar reads by itself from [MediaQuery] and the platform dispatcher.
class LiquidGlassPolicy extends InheritedWidget {
  /// Creates a policy for the bars below [child].
  const LiquidGlassPolicy({
    super.key,
    this.blurSupported = true,
    this.reduceTransparency = false,
    this.reduceMotion = false,
    required super.child,
  });

  /// False where blurring what is behind a widget is not possible or too slow: Android
  /// below 12 (API 31), where the blur needs `RenderEffect`. The bar is then opaque.
  final bool blurSupported;

  /// iOS's "Reduce Transparency" (Settings, Accessibility, Display & Text Size). The bar
  /// is then opaque.
  final bool reduceTransparency;

  /// Reduced motion that the app knows of beyond what Flutter reports. The bar is then
  /// opaque and its lens jumps from item to item.
  final bool reduceMotion;

  /// The nearest policy above [context], or null.
  static LiquidGlassPolicy? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiquidGlassPolicy>();

  @override
  bool updateShouldNotify(LiquidGlassPolicy oldWidget) =>
      blurSupported != oldWidget.blurSupported ||
      reduceTransparency != oldWidget.reduceTransparency ||
      reduceMotion != oldWidget.reduceMotion;
}
