import 'package:flutter/widgets.dart';

/// One place of a [LiquidGlassNavBar]: an icon (or the user's avatar) and a label.
///
/// There are three ways to give the glyph:
///
/// * the default constructor takes an [IconData] and, for the selected state, another;
/// * [LiquidGlassDestination.widget] takes any widget (an SVG, an image, an animation);
/// * [LiquidGlassDestination.avatar] draws a small round avatar from an image or initials.
@immutable
class LiquidGlassDestination {
  /// A destination with an icon from an [IconData], and optionally another for when it
  /// is selected (the filled variant of an outlined icon).
  const LiquidGlassDestination({
    required IconData this.icon,
    required this.label,
    this.selectedIcon,
    this.badgeCount,
  }) : iconWidget = null,
       selectedIconWidget = null,
       avatarImage = null,
       avatarInitials = null,
       isAvatar = false;

  /// A destination whose glyph is any widget. It is sized to the style's `iconSize`, and
  /// an [Icon] in it takes the item's colour (through an [IconTheme]).
  const LiquidGlassDestination.widget({
    required Widget icon,
    required this.label,
    Widget? selectedIcon,
    this.badgeCount,
  }) : iconWidget = icon,
       selectedIconWidget = selectedIcon,
       icon = null,
       selectedIcon = null,
       avatarImage = null,
       avatarInitials = null,
       isAvatar = false;

  /// A destination that shows the person: a round avatar, a photo ([image]) or, without
  /// one, the [initials]. When selected it has a ring of the selected colour.
  const LiquidGlassDestination.avatar({
    required this.label,
    ImageProvider? image,
    String? initials,
    this.badgeCount,
  }) : avatarImage = image,
       avatarInitials = initials,
       icon = null,
       selectedIcon = null,
       iconWidget = null,
       selectedIconWidget = null,
       isAvatar = true;

  /// The icon, null for a widget or avatar destination.
  final IconData? icon;

  /// The icon shown when selected; defaults to [icon].
  final IconData? selectedIcon;

  /// The glyph of a [LiquidGlassDestination.widget] destination.
  final Widget? iconWidget;

  /// The glyph shown when selected; defaults to [iconWidget].
  final Widget? selectedIconWidget;

  /// The photo of an avatar destination.
  final ImageProvider? avatarImage;

  /// The initials of an avatar destination, shown without a photo.
  final String? avatarInitials;

  /// Whether this is an avatar destination.
  final bool isAvatar;

  /// The text under the icon, and what a screen reader says. A label of more than nine
  /// characters, or wider than its slot, is shortened with a period on the bar
  /// ("Notifications" reads "Notific."); the full label is still spoken.
  final String label;

  /// A count shown in a badge at the icon's top end and spoken after the label; hidden
  /// when null or zero. Above 99 it reads "99+".
  final int? badgeCount;
}
