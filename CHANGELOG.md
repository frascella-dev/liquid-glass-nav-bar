## 0.1.0

* First release: `LiquidGlassNavBar`, a floating capsule of blurred glass with a lens that
  moves on touch-down, swells while pressed, squeezes by its speed and flings at most one
  item further.
* `LiquidGlassNavBarStyle` with light and dark defaults; icons from `IconData` or any
  widget, selected icons, count badges and an avatar item (`LiquidGlassDestination`).
* `LiquidGlassPolicy` and the opaque fallback (Android below 12, iOS Reduce Transparency,
  high contrast, Reduce Motion).
* Labels over nine characters are shortened with a period; every item is a button for
  screen readers; a focus ring from the keyboard only.
