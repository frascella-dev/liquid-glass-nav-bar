import 'package:flutter/material.dart';

/// How a [LiquidGlassNavBar] looks: colours, sizes and type.
///
/// Every field is optional. A field left null takes the default for the bar's
/// brightness (`Theme.of(context).brightness`, or [LiquidGlassNavBar.brightness]), so
/// `LiquidGlassNavBarStyle(selectedColor: Colors.orange)` changes the accent and nothing
/// else. [LiquidGlassNavBarStyle.light] and [LiquidGlassNavBarStyle.dark] hold the
/// complete defaults.
@immutable
class LiquidGlassNavBarStyle {
  /// Creates a style; null fields take the default of the brightness.
  const LiquidGlassNavBarStyle({
    this.height,
    this.sideMargin,
    this.bottomMargin,
    this.iconSize,
    this.blurSigma,
    this.saturation,
    this.glassColor,
    this.edgeColor,
    this.highlightColor,
    this.shadowColor,
    this.shadowNearColor,
    this.lensColor,
    this.lensEdgeColor,
    this.lensHighlightColor,
    this.selectedColor,
    this.unselectedColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.opaqueColor,
    this.opaqueBorderColor,
    this.opaqueLensColor,
    this.badgeColor,
    this.badgeTextColor,
    this.badgeRingColor,
    this.avatarColor,
    this.avatarForegroundColor,
    this.focusRingColor,
  });

  /// The complete defaults on a light backdrop: white glass, a blue lens.
  const LiquidGlassNavBarStyle.light()
    : height = 64,
      sideMargin = 16,
      bottomMargin = 24,
      iconSize = 24,
      blurSigma = 20,
      saturation = 1.8,
      glassColor = const Color(0x8CFFFFFF),
      edgeColor = const Color(0xC7FFFFFF),
      highlightColor = const Color(0xD9FFFFFF),
      shadowColor = const Color(0x2E111111),
      shadowNearColor = const Color(0x1A111111),
      lensColor = const Color(0x240A84FF),
      lensEdgeColor = const Color(0x330A84FF),
      lensHighlightColor = const Color(0xBFFFFFFF),
      selectedColor = const Color(0xFF0A6CDB),
      unselectedColor = const Color(0xFF1C1C1E),
      labelStyle = const TextStyle(fontSize: 10, height: 1.2, fontWeight: FontWeight.w500),
      selectedLabelStyle = const TextStyle(fontSize: 10, height: 1.2, fontWeight: FontWeight.w600),
      opaqueColor = const Color(0xFFFFFFFF),
      opaqueBorderColor = const Color(0x33000000),
      opaqueLensColor = const Color(0xFFDCEBFF),
      badgeColor = const Color(0xFFFF3B30),
      badgeTextColor = const Color(0xFFFFFFFF),
      badgeRingColor = const Color(0xFFF2F2F7),
      avatarColor = const Color(0xFF5E5CE6),
      avatarForegroundColor = const Color(0xFFFFFFFF),
      focusRingColor = null;

  /// The complete defaults on a dark backdrop: smoked glass, a light-blue lens.
  const LiquidGlassNavBarStyle.dark()
    : height = 64,
      sideMargin = 16,
      bottomMargin = 24,
      iconSize = 24,
      blurSigma = 20,
      saturation = 1.8,
      glassColor = const Color(0x8C1C1C1E),
      edgeColor = const Color(0x1FFFFFFF),
      highlightColor = const Color(0x1AFFFFFF),
      shadowColor = const Color(0x9E000000),
      shadowNearColor = const Color(0x73000000),
      lensColor = const Color(0x330A84FF),
      lensEdgeColor = const Color(0x4D64B5FF),
      lensHighlightColor = const Color(0x1FFFFFFF),
      selectedColor = const Color(0xFF64B5FF),
      unselectedColor = const Color(0xE6FFFFFF),
      labelStyle = const TextStyle(fontSize: 10, height: 1.2, fontWeight: FontWeight.w500),
      selectedLabelStyle = const TextStyle(fontSize: 10, height: 1.2, fontWeight: FontWeight.w600),
      opaqueColor = const Color(0xFF2C2C2E),
      opaqueBorderColor = const Color(0x40FFFFFF),
      opaqueLensColor = const Color(0xFF1F3A5C),
      badgeColor = const Color(0xFFFF453A),
      badgeTextColor = const Color(0xFFFFFFFF),
      badgeRingColor = const Color(0xFF2C2C2E),
      avatarColor = const Color(0xFF7D7AFF),
      avatarForegroundColor = const Color(0xFFFFFFFF),
      focusRingColor = null;

  /// The capsule's height. The slot of the bar is this plus [bottomMargin]. Default 64.
  final double? height;

  /// The distance of the capsule from the sides of the screen, in addition to the safe
  /// area. Default 16.
  final double? sideMargin;

  /// The distance of the capsule from the bottom edge of the screen. Default 24.
  final double? bottomMargin;

  /// The size of an icon or avatar. Default 24.
  final double? iconSize;

  /// The blur of what is behind the capsule. Default 20.
  final double? blurSigma;

  /// The saturation of what is behind the capsule (1 is unchanged). Default 1.8.
  final double? saturation;

  /// The tint over the blurred backdrop.
  final Color? glassColor;

  /// The 1 px line inside the capsule's edge.
  final Color? edgeColor;

  /// The highlight along the top of the capsule.
  final Color? highlightColor;

  /// The wide soft shadow under the capsule.
  final Color? shadowColor;

  /// The tight shadow under the capsule.
  final Color? shadowNearColor;

  /// The lens's tint, at rest. It brightens while the lens is pressed.
  final Color? lensColor;

  /// The lens's edge line.
  final Color? lensEdgeColor;

  /// The highlight along the lens's top.
  final Color? lensHighlightColor;

  /// The colour of the selected item's icon and label, and of the avatar and focus rings.
  final Color? selectedColor;

  /// The colour of the other items' icons and labels.
  final Color? unselectedColor;

  /// The labels' style; its colour is overridden by [selectedColor] and
  /// [unselectedColor]. Default 10 on 12, medium weight.
  final TextStyle? labelStyle;

  /// The selected label's style. Default semibold.
  final TextStyle? selectedLabelStyle;

  /// The capsule's fill when the bar is opaque (see [LiquidGlassPolicy]).
  final Color? opaqueColor;

  /// The capsule's edge when opaque.
  final Color? opaqueBorderColor;

  /// The lens's fill when opaque.
  final Color? opaqueLensColor;

  /// The count badge's fill.
  final Color? badgeColor;

  /// The count badge's number.
  final Color? badgeTextColor;

  /// The ring around the count badge, the colour of what is under it.
  final Color? badgeRingColor;

  /// The avatar's background when it shows initials.
  final Color? avatarColor;

  /// The avatar's initials.
  final Color? avatarForegroundColor;

  /// The keyboard focus ring; defaults to [selectedColor].
  final Color? focusRingColor;

  /// This style with every field that [other] sets replaced by it.
  LiquidGlassNavBarStyle merge(LiquidGlassNavBarStyle? other) {
    if (other == null) return this;
    return LiquidGlassNavBarStyle(
      height: other.height ?? height,
      sideMargin: other.sideMargin ?? sideMargin,
      bottomMargin: other.bottomMargin ?? bottomMargin,
      iconSize: other.iconSize ?? iconSize,
      blurSigma: other.blurSigma ?? blurSigma,
      saturation: other.saturation ?? saturation,
      glassColor: other.glassColor ?? glassColor,
      edgeColor: other.edgeColor ?? edgeColor,
      highlightColor: other.highlightColor ?? highlightColor,
      shadowColor: other.shadowColor ?? shadowColor,
      shadowNearColor: other.shadowNearColor ?? shadowNearColor,
      lensColor: other.lensColor ?? lensColor,
      lensEdgeColor: other.lensEdgeColor ?? lensEdgeColor,
      lensHighlightColor: other.lensHighlightColor ?? lensHighlightColor,
      selectedColor: other.selectedColor ?? selectedColor,
      unselectedColor: other.unselectedColor ?? unselectedColor,
      labelStyle: other.labelStyle ?? labelStyle,
      selectedLabelStyle: other.selectedLabelStyle ?? selectedLabelStyle,
      opaqueColor: other.opaqueColor ?? opaqueColor,
      opaqueBorderColor: other.opaqueBorderColor ?? opaqueBorderColor,
      opaqueLensColor: other.opaqueLensColor ?? opaqueLensColor,
      badgeColor: other.badgeColor ?? badgeColor,
      badgeTextColor: other.badgeTextColor ?? badgeTextColor,
      badgeRingColor: other.badgeRingColor ?? badgeRingColor,
      avatarColor: other.avatarColor ?? avatarColor,
      avatarForegroundColor: other.avatarForegroundColor ?? avatarForegroundColor,
      focusRingColor: other.focusRingColor ?? focusRingColor,
    );
  }

  /// A copy with the given fields replaced.
  LiquidGlassNavBarStyle copyWith({
    double? height,
    double? sideMargin,
    double? bottomMargin,
    double? iconSize,
    double? blurSigma,
    double? saturation,
    Color? glassColor,
    Color? edgeColor,
    Color? highlightColor,
    Color? shadowColor,
    Color? shadowNearColor,
    Color? lensColor,
    Color? lensEdgeColor,
    Color? lensHighlightColor,
    Color? selectedColor,
    Color? unselectedColor,
    TextStyle? labelStyle,
    TextStyle? selectedLabelStyle,
    Color? opaqueColor,
    Color? opaqueBorderColor,
    Color? opaqueLensColor,
    Color? badgeColor,
    Color? badgeTextColor,
    Color? badgeRingColor,
    Color? avatarColor,
    Color? avatarForegroundColor,
    Color? focusRingColor,
  }) => merge(
    LiquidGlassNavBarStyle(
      height: height,
      sideMargin: sideMargin,
      bottomMargin: bottomMargin,
      iconSize: iconSize,
      blurSigma: blurSigma,
      saturation: saturation,
      glassColor: glassColor,
      edgeColor: edgeColor,
      highlightColor: highlightColor,
      shadowColor: shadowColor,
      shadowNearColor: shadowNearColor,
      lensColor: lensColor,
      lensEdgeColor: lensEdgeColor,
      lensHighlightColor: lensHighlightColor,
      selectedColor: selectedColor,
      unselectedColor: unselectedColor,
      labelStyle: labelStyle,
      selectedLabelStyle: selectedLabelStyle,
      opaqueColor: opaqueColor,
      opaqueBorderColor: opaqueBorderColor,
      opaqueLensColor: opaqueLensColor,
      badgeColor: badgeColor,
      badgeTextColor: badgeTextColor,
      badgeRingColor: badgeRingColor,
      avatarColor: avatarColor,
      avatarForegroundColor: avatarForegroundColor,
      focusRingColor: focusRingColor,
    ),
  );

  /// The complete style for [brightness] with [override] on top.
  static LiquidGlassNavBarStyle resolve(
    Brightness brightness, [
    LiquidGlassNavBarStyle? override,
  ]) =>
      (brightness == Brightness.dark
              ? const LiquidGlassNavBarStyle.dark()
              : const LiquidGlassNavBarStyle.light())
          .merge(override);
}
