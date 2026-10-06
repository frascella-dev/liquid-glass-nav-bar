import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import 'glass_nav_bar_style.dart';
import 'glass_nav_destination.dart';
import 'glass_policy.dart';

/// A floating bottom navigation bar of liquid glass: a capsule that blurs what scrolls
/// under it, with a lens of glass that follows the finger on springs, as iOS's tab bar.
///
/// Put it in the [Scaffold]'s `bottomNavigationBar` of a scaffold with `extendBody: true`,
/// so the screen scrolls under it, or in a [Stack]. It is [slotHeight] high (the capsule
/// and the space under it); the body sees that as its bottom padding.
///
/// **The capsule.** [LiquidGlassNavBarStyle.height] (64) high, `sideMargin` (16) from the
/// sides plus the side safe areas, `bottomMargin` (24) from the bottom edge. A
/// [BackdropFilter] blurs what is under it (`blurSigma` 20, `saturation` 1.8) under a tint,
/// a 1 px edge line, a highlight along the top and a soft shadow outside. While a finger
/// is on it the whole capsule grows by [pressGrow] (4 %) from its centre, and eases back on
/// a soft spring.
///
/// **The items.** Two to five [LiquidGlassDestination]s in equal slots, [inset] (4) from
/// the capsule's top and bottom and [sideInset] (10) from its ends: an icon, the label 4
/// under it, the selected one in the style's `selectedColor` with its `selectedIcon`. A
/// label longer than [labelMaxCharacters] (9), or wider than the lens less [labelInset]
/// on each side, is shortened with a period ("Notifications" reads "Notific.",
/// [shortenLabel]); the full label is spoken.
///
/// **The lens.** The selected item sits under a lens: at rest a pill the item's height
/// and its slot plus [lensExtra] (12) wide, centred on the item; on the first and the last
/// it is concentric in the capsule, [inset] from its end, top and bottom (radius 28
/// against the capsule's 32 with the default height). It is a drop of glass on springs,
/// integrated frame by frame:
///
/// * **Touched, dragged or travelling** it swells beyond the capsule, [liftGrowY] (30 %)
///   taller and [liftGrowX] (22 %) wider; its tint brightens; the icon and label under it
///   grow by [magnification] (10 %), as through a lens.
/// * **Moving** it squeezes by its own speed: longer along the motion and thinner across
///   it, its area kept ([stretch], full at [stretchSpeed]), springing back with a wobble.
/// * **Touched on another item** it leaves for it at once, on touch-down; lifting the
///   finger there selects it; a touch that ends in neither a tap nor a drag sends it back
///   to the selected item.
/// * **Dragged** (past the touch slop) it follows the finger a little behind, the item
///   under it lit; past the ends it gives a little ([edgeGive]). On release it lands on
///   the item under it; faster than [flingThreshold] (900 px/s) its momentum, projected
///   [flingProjection] ahead, carries it at most one item further.
/// * **Tapped** it stays swollen as it slides to the item, and shrinks back as it lands.
///
/// Every frame moves only transforms and paint, never layout.
///
/// **Fewer effects.** The capsule is opaque ([isOpaque]) when the platform cannot blur or
/// asks for fewer effects: Android below 12 and iOS's Reduce Transparency (from a
/// [LiquidGlassPolicy]), high contrast, "Remove animations" and Reduce Motion. With
/// reduced motion ([reducesMotion]) nothing swells, grows, squeezes or wobbles: the lens
/// jumps to the item.
///
/// Every item is a button with its selected state, reachable from the keyboard and by
/// screen readers. Focused from the keyboard (and only then) it shows a [focusRingWidth]
/// ring around its lens shape; there is no ink or overlay.
class LiquidGlassNavBar extends StatefulWidget {
  /// Creates a bar of [destinations] (two to five) with [selectedIndex] selected;
  /// [onSelected] is called with the index a tap, a drag or a fling selects.
  const LiquidGlassNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.style,
    this.brightness,
    this.debugLensLift,
  }) : assert(destinations.length >= 2 && destinations.length <= 5),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  /// The places, two to five.
  final List<LiquidGlassDestination> destinations;

  /// The index of the selected place.
  final int selectedIndex;

  /// Called with the index of the place a tap, a drag or a fling selects.
  final ValueChanged<int> onSelected;

  /// The look; null fields take the default of the [brightness].
  final LiquidGlassNavBarStyle? style;

  /// Which defaults to start from, light or dark; defaults to `Theme.of(context).brightness`.
  final Brightness? brightness;

  /// Holds the lens (and the capsule) pressed at this value, 0 at rest and 1 pressed, for
  /// screenshots and tests; null normally, where the finger presses it.
  @visibleForTesting
  final double? debugLensLift;

  /// The capsule's default height.
  static const double height = 64;

  /// The default distance of the capsule from the sides.
  static const double sideMargin = 16;

  /// The default distance of the capsule from the bottom.
  static const double bottomMargin = 24;

  /// The default slot's height: the capsule and the space under it.
  static const double slotHeight = height + bottomMargin;

  /// The gap between the lens at rest and the capsule's top, bottom and ends.
  static const double inset = 4;

  /// The items' inset from the capsule's ends: the slots start here, so the end lenses,
  /// [lensExtra] wider than their slot, sit [inset] from the capsule's end as from its
  /// top and bottom: concentric with it.
  static const double sideInset = inset + lensExtra / 2;

  /// How much wider than its slot the lens is at rest (6 on each side), as iOS's tab bar.
  static const double lensExtra = 12;

  /// The width of the badge's ring.
  static const double ringWidth = 2;

  /// The width of the keyboard focus ring.
  static const double focusRingWidth = 2;

  /// The gap between an icon and its label.
  static const double labelGap = 4;

  /// A label longer than this is shortened ("Notifications", 13, becomes "Notific.").
  static const int labelMaxCharacters = 9;

  /// A shortened label, its period included, is at most this long.
  static const int shortLabelMaxCharacters = 8;

  /// The breathing room on each side of a label inside its lens.
  static const double labelInset = 8;

  /// The lens's slide and snap: elastic, overshooting, settling in a swing or two.
  static final SpringDescription spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.58,
  );

  /// The swell on press: quick, without overshoot.
  static final SpringDescription pressSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 900,
    ratio: 1,
  );

  /// The return to rest on release: the soft wobble of a drop.
  static final SpringDescription releaseSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 480,
    ratio: 0.4,
  );

  /// The capsule's growth on press and its return: soft.
  static final SpringDescription growSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 360,
    ratio: 0.8,
  );

  /// The dragged lens following the finger, a little behind it.
  static final SpringDescription followSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 700,
    ratio: 0.75,
  );

  /// The squeeze following the speed, and springing back round.
  static final SpringDescription stretchSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 520,
    ratio: 0.5,
  );

  /// How much the pressed lens grows in height, beyond the capsule.
  static const double liftGrowY = 0.30;

  /// How much the pressed lens grows in width.
  static const double liftGrowX = 0.22;

  /// How much the whole capsule grows while a finger is on it.
  static const double pressGrow = 0.04;

  /// How much brighter the pressed lens's tint is.
  static const double liftTint = 1.4;

  /// How much brighter the pressed lens's edge is.
  static const double liftEdge = 1.8;

  /// How much brighter the pressed lens's highlight is.
  static const double liftHighlight = 1.6;

  /// How much the icon and label under the pressed lens grow.
  static const double magnification = 0.10;

  /// The squeeze at full speed: the lens this much longer along the motion, and thinner
  /// across it by as much as keeps its area.
  static const double stretch = 0.3;

  /// The speed, in logical pixels a second, at which the squeeze is full.
  static const double stretchSpeed = 2200;

  /// How far ahead, in seconds of its release velocity, a flung lens looks for the item
  /// it lands on: at most one item past the one it is released over.
  static const double flingProjection = 0.06;

  /// The release speed, in logical pixels a second, under which a drag has no momentum.
  static const double flingThreshold = 900;

  /// How far, in items, the dragged lens gives past the first and the last item.
  static const double edgeGive = 0.2;

  /// A tap's swell reaches at least this before the lens settles.
  static const double swellPeak = 0.8;

  /// Whether the platform asks for fewer animations: "Remove animations" on Android,
  /// Reduce Motion on iOS, or the [LiquidGlassPolicy]. The lens then jumps.
  static bool reducesMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      (LiquidGlassPolicy.maybeOf(context)?.reduceMotion ?? false) ||
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion;

  /// Whether the capsule is opaque instead of glass: no blur on the platform, Reduce
  /// Transparency, high contrast, or reduced motion.
  static bool isOpaque(BuildContext context) {
    final policy = LiquidGlassPolicy.maybeOf(context);
    return !(policy?.blurSupported ?? true) ||
        (policy?.reduceTransparency ?? false) ||
        MediaQuery.highContrastOf(context) ||
        reducesMotion(context);
  }

  /// [label] as the bar shows it in [maxWidth] (the lens less [labelInset] on each side)
  /// and [style], measured in whole pixels: whole when it has at most [labelMaxCharacters]
  /// and fits; otherwise the longest prefix, cut after a letter, that fits with its
  /// period in [shortLabelMaxCharacters] and [maxWidth] ("Notifications" becomes "Notific.").
  static String shortenLabel(String label, TextStyle style, double maxWidth, TextScaler scaler) {
    double widthOf(String s) {
      final painter = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      // In whole pixels, so a label a hair wider than the room is not cut for it.
      final width = painter.width.roundToDouble();
      painter.dispose();
      return width;
    }

    final characters = label.characters.toList();
    if (characters.length <= labelMaxCharacters && widthOf(label) <= maxWidth) {
      return label;
    }
    final letter = RegExp(r'[\p{L}\p{N}]', unicode: true);
    for (var n = math.min(characters.length - 1, shortLabelMaxCharacters - 1); n > 0; n--) {
      final prefix = characters.take(n).toList();
      while (prefix.length > 1 && !letter.hasMatch(prefix.last)) {
        prefix.removeLast();
      }
      final candidate = '${prefix.join()}.';
      if (widthOf(candidate) <= maxWidth) return candidate;
    }
    return '${characters.first}.';
  }

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> with TickerProviderStateMixin {
  static const _tolerance = Tolerance(distance: 0.001, velocity: 0.01);

  /// The lens's place, in items from the start (0 is the first item), integrated frame by
  /// frame by [_ticker]; the painters and the items listen to it.
  late final ValueNotifier<double> _position = ValueNotifier(widget.selectedIndex.toDouble())
    ..addListener(_onPosition);

  /// The lens's velocity, in items a second, and where its spring pulls it.
  double _velocity = 0;
  late double _target = widget.selectedIndex.toDouble();

  /// How pressed the lens is: 0 at rest, 1 swollen; a little past either while it wobbles.
  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
    value: widget.debugLensLift ?? 0,
  )..addListener(_onLift);

  /// How much the whole capsule has grown: 0 at rest, 1 pressed.
  late final AnimationController _grow = AnimationController.unbounded(
    vsync: this,
    value: widget.debugLensLift ?? 0,
  );

  /// The squeeze, 0 round and 1 at full speed, following the lens's own speed.
  final ValueNotifier<double> _stretch = ValueNotifier(0);
  double _stretchVelocity = 0;

  /// The physics of the lens: its place and its squeeze, both springs.
  late final Ticker _ticker = createTicker(_tick);
  Duration _lastTick = Duration.zero;

  /// The item drawn as selected: the selected one, or the one under the dragged lens.
  late final ValueNotifier<int> _lit = ValueNotifier(widget.selectedIndex);

  int? _pointer;
  bool _dragging = false;

  /// A tap swells the lens; it shrinks back once swollen ([_swellPending]) or, when the
  /// tap moves it, once it is about to land ([_landPending]).
  bool _swellPending = false;
  bool _landPending = false;

  /// Whether the touch under way ended in a selection (a tap, a drag's end).
  bool _settled = false;
  double _grabOffset = 0;
  double _itemWidth = 1;
  double _barWidth = 0;
  bool _reduced = false;
  bool _rtl = false;

  int get _last => widget.destinations.length - 1;
  double get _direction => _rtl ? -1 : 1;
  bool get _animated => !_reduced && widget.debugLensLift == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = LiquidGlassNavBar.reducesMotion(context);
    _rtl = Directionality.of(context) == TextDirection.rtl;
  }

  @override
  void didUpdateWidget(LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lift = widget.debugLensLift;
    if (lift != null && lift != oldWidget.debugLensLift) {
      _lift.value = lift;
      _grow.value = lift;
    }
    if (!_dragging && widget.selectedIndex != oldWidget.selectedIndex) {
      _lit.value = widget.selectedIndex;
      _moveTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _position.dispose();
    _lift.dispose();
    _grow.dispose();
    _stretch.dispose();
    _lit.dispose();
    super.dispose();
  }

  void _onPosition() {
    if (_dragging) _lit.value = _position.value.round().clamp(0, _last);
  }

  void _onLift() {
    if (_swellPending && _lift.value >= LiquidGlassNavBar.swellPeak) {
      _swellPending = false;
      _release();
    }
  }

  // The press -----------------------------------------------------------------------

  void _spring(AnimationController c, SpringDescription spring, double target) {
    c.animateWith(SpringSimulation(spring, c.value, target, c.velocity, tolerance: _tolerance));
  }

  void _press() {
    if (!_animated) return;
    _spring(_lift, LiquidGlassNavBar.pressSpring, 1);
    _spring(_grow, LiquidGlassNavBar.pressSpring, 1);
  }

  void _release() {
    if (!_animated) return;
    _landPending = false;
    _spring(_lift, LiquidGlassNavBar.releaseSpring, 0);
    _spring(_grow, LiquidGlassNavBar.growSpring, 0);
  }

  /// A tap without a press before it (the keyboard, a screen reader): the swell alone.
  void _swell() {
    if (!_animated || _pointer != null || _lift.isAnimating || _lift.value > 0.05) {
      return;
    }
    _swellPending = true;
    _press();
  }

  // The physics ---------------------------------------------------------------------

  /// Sends the lens to [index] on [LiquidGlassNavBar.spring], keeping its velocity.
  void _moveTo(int index) {
    final target = index.clamp(0, _last).toDouble();
    if (_reduced) {
      _target = target;
      _velocity = 0;
      _position.value = target;
      return;
    }
    _target = target;
    _startTicker();
  }

  void _startTicker() {
    if (_reduced || _ticker.isActive) return;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  /// One frame: the lens's spring (towards the finger while dragged, towards its item
  /// after) and the squeeze's spring (towards the lens's speed), in steps of 1/240 s.
  void _tick(Duration elapsed) {
    // The first frame moves too: the lens leaves on the frame after the touch.
    var dt = elapsed == Duration.zero
        ? 1 / 120
        : math.min((elapsed - _lastTick).inMicroseconds / Duration.microsecondsPerSecond, 1 / 30);
    _lastTick = elapsed;
    if (dt <= 0) return;
    final p = _dragging ? LiquidGlassNavBar.followSpring : LiquidGlassNavBar.spring;
    final q = LiquidGlassNavBar.stretchSpring;
    var x = _position.value, v = _velocity, s = _stretch.value, sv = _stretchVelocity;
    while (dt > 0) {
      final h = math.min(dt, 1 / 240);
      v += (-p.stiffness * (x - _target) - p.damping * v) / p.mass * h;
      x += v * h;
      final speed = (v * _itemWidth).abs() / LiquidGlassNavBar.stretchSpeed;
      sv += (-q.stiffness * (s - speed.clamp(0.0, 1.0)) - q.damping * sv) / q.mass * h;
      s = (s + sv * h).clamp(-0.3, 1.2);
      dt -= h;
    }
    final settled =
        !_dragging &&
        (x - _target).abs() < 0.001 &&
        v.abs() < 0.01 &&
        s.abs() < 0.002 &&
        sv.abs() < 0.02;
    if (settled) {
      x = _target;
      v = s = sv = 0;
      _ticker.stop();
    }
    _velocity = v;
    _stretchVelocity = sv;
    _position.value = x;
    _stretch.value = s;
    if (_landPending && (x - _target).abs() < 0.3) _release();
  }

  // The finger ----------------------------------------------------------------------

  /// A finger down: the lens lifts and, on another item, leaves for it at once; lifting
  /// the finger there selects it (a tap), a drag takes over from where the lens is.
  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _swellPending = false;
    _landPending = false;
    _settled = false;
    _press();
    if (!_reduced) _moveTo(_under(event.localPosition).round().clamp(0, _last));
  }

  void _onPointerUp(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    // The tap or the drag's end, dispatched after this listener, settles the lens; a
    // touch that neither confirms (cancelled, or lifted off the item) sends it back.
    scheduleMicrotask(() {
      if (!mounted || _settled || _dragging) return;
      _lit.value = widget.selectedIndex;
      _moveTo(widget.selectedIndex);
      if (_animated) _landPending = true;
    });
    if (!_animated || _dragging) return;
    if ((_target - _position.value).abs() >= 0.3) {
      // Still travelling to the touched item: swollen until it lands.
      _landPending = true;
    } else {
      // A quick tap still swells before the lens settles.
      _swellPending = _lift.value < LiquidGlassNavBar.swellPeak;
      if (!_swellPending) _release();
    }
  }

  void _select(int index) {
    _settled = true;
    _swell();
    if (index != widget.selectedIndex) widget.onSelected(index);
    // Moving, the lens stays swollen until it is about to land.
    if (_animated && (index - _position.value).abs() >= 0.5) {
      _swellPending = false;
      _landPending = true;
      _press();
    }
    _moveTo(index);
  }

  /// The lens's place under a finger at [local] (in the capsule), in items.
  double _under(Offset local) {
    final x = _rtl ? _barWidth - local.dx : local.dx;
    return (x - LiquidGlassNavBar.sideInset) / _itemWidth - 0.5;
  }

  /// [place] kept on the bar, giving a little past its ends.
  double _give(double place) {
    const give = LiquidGlassNavBar.edgeGive;
    double soft(double excess) => give * (1 - math.exp(-excess / give / 2));
    if (place < 0) return -soft(-place);
    if (place > _last) return _last + soft(place - _last);
    return place;
  }

  void _onDragStart(DragStartDetails details) {
    _dragging = true;
    _swellPending = false;
    _landPending = false;
    final finger = _under(details.localPosition);
    final offset = _position.value - finger;
    // Grabbed on the lens: it keeps its place under the finger; elsewhere it comes there.
    _grabOffset = offset.abs() <= 0.5 ? offset : 0;
    _press();
    _follow(finger + _grabOffset);
  }

  void _onDragUpdate(DragUpdateDetails details) =>
      _follow(_under(details.localPosition) + _grabOffset);

  /// The finger at [place]: the lens follows on [LiquidGlassNavBar.followSpring],
  /// a little behind, as a liquid would.
  void _follow(double place) {
    if (_reduced) {
      final item = place.round().clamp(0, _last).toDouble();
      _target = item;
      _position.value = item;
      return;
    }
    _target = _give(place);
    _startTicker();
  }

  void _onDragEnd(DragEndDetails details) => _endDrag(details.velocity.pixelsPerSecond.dx);

  /// The finger lifts at [velocity] (pixels a second): the lens lands on the item under
  /// it, or, faster than [LiquidGlassNavBar.flingThreshold], on the item its
  /// momentum reaches [LiquidGlassNavBar.flingProjection] ahead, never more than
  /// one past; on the bouncy [LiquidGlassNavBar.spring], keeping its velocity.
  void _endDrag(double velocity) {
    _dragging = false;
    _settled = true;
    final over = _position.value.round().clamp(0, _last);
    var target = over;
    if (velocity.abs() > LiquidGlassNavBar.flingThreshold) {
      final fling = _direction * velocity / _itemWidth;
      final projected = (_position.value + fling * LiquidGlassNavBar.flingProjection).round();
      target = projected.clamp(over - 1, over + 1).clamp(0, _last);
      // It keeps the momentum, tamed so the landing overshoots and does not fly.
      if (!_reduced) _velocity = fling.clamp(-8.0, 8.0);
    }
    _lit.value = target;
    if (target != widget.selectedIndex) widget.onSelected(target);
    // Still travelling, the lens stays swollen until it is about to land.
    if (_animated && (target - _position.value).abs() >= 0.3) {
      _landPending = true;
    } else {
      _release();
    }
    _moveTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.brightness ?? Theme.of(context).brightness;
    final st = LiquidGlassNavBarStyle.resolve(brightness, widget.style);
    final opaque = LiquidGlassNavBar.isOpaque(context);
    final padding = MediaQuery.paddingOf(context);
    final capsuleHeight = st.height!;
    final bottomMargin = st.bottomMargin!;
    final itemHeight = capsuleHeight - 2 * LiquidGlassNavBar.inset;
    const shape = StadiumBorder();

    final Widget fill = opaque
        ? DecoratedBox(
            decoration: ShapeDecoration(
              shape: StadiumBorder(side: BorderSide(color: st.opaqueBorderColor!)),
              color: st.opaqueColor,
            ),
          )
        : ClipPath(
            clipper: const ShapeBorderClipper(shape: shape),
            child: BackdropFilter(
              filter: ui.ImageFilter.compose(
                outer: ui.ImageFilter.blur(sigmaX: st.blurSigma!, sigmaY: st.blurSigma!),
                inner: ColorFilter.matrix(_saturationMatrix(st.saturation!)),
              ),
              child: ColoredBox(color: st.glassColor!),
            ),
          );

    final lens = _LensPainter(
      lift: _lift,
      stretch: _stretch,
      fill: opaque ? st.opaqueLensColor! : st.lensColor!,
      edge: st.lensEdgeColor!,
      highlight: opaque ? null : st.lensHighlightColor,
    );

    return SizedBox(
      height: capsuleHeight + bottomMargin,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          st.sideMargin! + padding.left,
          0,
          st.sideMargin! + padding.right,
          bottomMargin,
        ),
        child: AnimatedBuilder(
          animation: _grow,
          builder: (context, child) =>
              Transform.scale(scale: 1 + LiquidGlassNavBar.pressGrow * _grow.value, child: child),
          child: CustomPaint(
            painter: _ShadowPainter(near: st.shadowNearColor!, far: st.shadowColor!),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _barWidth = constraints.maxWidth;
                _itemWidth =
                    (_barWidth - 2 * LiquidGlassNavBar.sideInset) / widget.destinations.length;
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: _onPointerDown,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerUp,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: _onDragStart,
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: _onDragEnd,
                    onHorizontalDragCancel: () => _endDrag(0),
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        fill,
                        if (!opaque)
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _EdgePainter(
                                edge: st.edgeColor!,
                                highlight: st.highlightColor!,
                              ),
                            ),
                          ),
                        // The lens, drawn over the capsule and free to overflow it.
                        PositionedDirectional(
                          start: LiquidGlassNavBar.sideInset,
                          top: LiquidGlassNavBar.inset,
                          width: _itemWidth,
                          height: itemHeight,
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _position,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(_direction * _position.value * _itemWidth, 0),
                                child: child,
                              ),
                              child: CustomPaint(painter: lens),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LiquidGlassNavBar.sideInset,
                            vertical: LiquidGlassNavBar.inset,
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Row(
                              children: [
                                for (final (i, d) in widget.destinations.indexed)
                                  Expanded(
                                    child: _Magnified(
                                      index: i,
                                      position: _position,
                                      lift: _lift,
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _lit,
                                        builder: (context, lit, _) => _Item(
                                          destination: d,
                                          selected: i == lit,
                                          style: st,
                                          height: itemHeight,
                                          onTap: () => _select(i),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// An item grown as seen through the pressed lens, by how much of the lens is over it.
class _Magnified extends StatelessWidget {
  const _Magnified({
    required this.index,
    required this.position,
    required this.lift,
    required this.child,
  });

  final int index;
  final ValueListenable<double> position;
  final Animation<double> lift;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([position, lift]),
    builder: (context, child) {
      final over = (1 - (position.value - index).abs()).clamp(0.0, 1.0);
      final scale = 1 + LiquidGlassNavBar.magnification * math.max(lift.value, 0) * over;
      return Transform.scale(scale: scale, child: child);
    },
    child: child,
  );
}

/// One item: icon (or avatar) and label, a badge for a count.
class _Item extends StatefulWidget {
  const _Item({
    required this.destination,
    required this.selected,
    required this.style,
    required this.height,
    required this.onTap,
  });

  final LiquidGlassDestination destination;
  final bool selected;
  final LiquidGlassNavBarStyle style;
  final double height;
  final VoidCallback onTap;

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    if (_focused) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.style;
    final d = widget.destination;
    final selected = widget.selected;
    final onTap = widget.onTap;
    final iconSize = st.iconSize!;
    // The ring only from the keyboard (or a traversal), never on touch.
    final ring = _focused && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final color = selected ? st.selectedColor! : st.unselectedColor!;
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final style = (selected ? st.selectedLabelStyle! : st.labelStyle!).copyWith(color: color);

    final Widget glyph;
    if (d.isAvatar) {
      glyph = DecoratedBox(
        decoration: ShapeDecoration(
          shape: CircleBorder(
            side: selected
                ? BorderSide(
                    color: st.selectedColor!,
                    width: LiquidGlassNavBar.ringWidth,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )
                : BorderSide.none,
          ),
        ),
        child: _Avatar(destination: d, size: iconSize, style: st),
      );
    } else if (d.iconWidget != null) {
      final w = selected ? (d.selectedIconWidget ?? d.iconWidget!) : d.iconWidget!;
      glyph = IconTheme(
        data: IconThemeData(color: color, size: iconSize),
        child: SizedBox.square(
          dimension: iconSize,
          child: FittedBox(child: w),
        ),
      );
    } else {
      glyph = Icon(selected ? (d.selectedIcon ?? d.icon) : d.icon, size: iconSize, color: color);
    }

    final count = d.badgeCount ?? 0;
    return Semantics(
      button: true,
      selected: selected,
      label: d.label,
      value: count > 0 ? '$count' : null,
      container: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        excludeFromSemantics: true,
        // The lens is the only feedback: no ink, splash, highlight, hover or focus overlay.
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: widget.height,
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Measured in the regular weight whether selected or not, so a label
                    // does not change when its item is selected.
                    final label = LiquidGlassNavBar.shortenLabel(
                      d.label,
                      base.merge(st.labelStyle),
                      // The label's room is the lens's (the slot and its extra), less the
                      // breathing room on each side.
                      constraints.maxWidth +
                          LiquidGlassNavBar.lensExtra -
                          2 * LiquidGlassNavBar.labelInset,
                      scaler,
                    );
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox.square(
                              dimension: iconSize,
                              child: Center(child: glyph),
                            ),
                            const SizedBox(height: LiquidGlassNavBar.labelGap),
                            Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              textScaler: scaler,
                              style: style,
                            ),
                          ],
                        ),
                        if (count > 0)
                          PositionedDirectional(
                            top: 4,
                            start: constraints.maxWidth / 2 + 4,
                            child: _Badge(count: count, style: st),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (ring)
              Positioned(
                left: -LiquidGlassNavBar.lensExtra / 2,
                right: -LiquidGlassNavBar.lensExtra / 2,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: st.focusRingColor ?? st.selectedColor!,
                          width: LiquidGlassNavBar.focusRingWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A round avatar: the photo or, without one, the initials on [LiquidGlassNavBarStyle.avatarColor].
class _Avatar extends StatelessWidget {
  const _Avatar({required this.destination, required this.size, required this.style});

  final LiquidGlassDestination destination;
  final double size;
  final LiquidGlassNavBarStyle style;

  @override
  Widget build(BuildContext context) {
    final image = destination.avatarImage;
    final initials = destination.avatarInitials;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.avatarColor,
        image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: image != null || initials == null
          ? null
          : Text(
              initials,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: style.avatarForegroundColor,
                fontSize: size * 0.4,
                height: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.style});

  final int count;
  final LiquidGlassNavBarStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      constraints: const BoxConstraints(minWidth: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: style.badgeColor,
        shape: StadiumBorder(
          side: BorderSide(
            color: style.badgeRingColor!,
            width: LiquidGlassNavBar.ringWidth,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          color: style.badgeTextColor,
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The soft shadow outside the capsule only, as CSS draws a box shadow: the glass shows
/// what is under it, not its own shadow.
class _ShadowPainter extends CustomPainter {
  const _ShadowPainter({required this.near, required this.far});

  final Color near;
  final Color far;

  @override
  void paint(Canvas canvas, Size size) {
    final capsule = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(64))
      ..addRRect(capsule);
    canvas
      ..save()
      ..clipPath(outside);
    for (final (color, dy, blur) in [(far, 12.0, 32.0), (near, 2.0, 8.0)]) {
      canvas.drawRRect(
        capsule.shift(Offset(0, dy)),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(blur)),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.near != near || old.far != far;
}

/// The light edge of the glass: a 1 px line inside the capsule's edge, and the highlight
/// along its top (an inset shadow 1 px down).
class _EdgePainter extends CustomPainter {
  const _EdgePainter({required this.edge, required this.highlight});

  final Color edge;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    _paintRim(canvas, Offset.zero & size, edge: edge, highlight: highlight);
  }

  @override
  bool shouldRepaint(_EdgePainter old) => old.edge != edge || old.highlight != highlight;
}

/// The lens: a pill of tinted glass with its edge and highlight, as large as its box (the
/// item's slot) at rest; swollen, wider and brighter as it is pressed or travels ([lift]),
/// longer and thinner as it moves ([stretch]), around the slot's centre and free to
/// overflow it.
class _LensPainter extends CustomPainter {
  _LensPainter({
    required this.lift,
    required this.stretch,
    required this.fill,
    required this.edge,
    this.highlight,
  }) : super(repaint: Listenable.merge([lift, stretch]));

  final Animation<double> lift;
  final ValueNotifier<double> stretch;
  final Color fill;
  final Color edge;
  final Color? highlight;

  static Color _brighter(Color color, double factor, double t) =>
      color.withValues(alpha: math.min(1, color.a * (1 + (factor - 1) * t)));

  @override
  void paint(Canvas canvas, Size size) {
    // At rest the item's slot and [LiquidGlassNavBar.lensExtra]; pressed it
    // swells, moving it squeezes (its area kept), always around the slot's centre.
    const extra = LiquidGlassNavBar.lensExtra / 2;
    final rest = Rect.fromLTRB(-extra, 0, size.width + extra, size.height);
    final l = lift.value;
    final along = 1 + LiquidGlassNavBar.stretch * stretch.value;
    final rect = Rect.fromCenter(
      center: rest.center,
      width: rest.width * (1 + LiquidGlassNavBar.liftGrowX * l) * along,
      height: rest.height * (1 + LiquidGlassNavBar.liftGrowY * l) / along,
    );
    final t = l.clamp(0.0, 1.0);
    final glow = highlight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      Paint()..color = _brighter(fill, LiquidGlassNavBar.liftTint, t),
    );
    _paintRim(
      canvas,
      rect,
      edge: _brighter(edge, LiquidGlassNavBar.liftEdge, t),
      highlight: glow == null ? null : _brighter(glow, LiquidGlassNavBar.liftHighlight, t),
      line: 1 + 0.5 * t,
    );
  }

  @override
  bool shouldRepaint(_LensPainter old) =>
      old.lift != lift ||
      old.stretch != stretch ||
      old.fill != fill ||
      old.edge != edge ||
      old.highlight != highlight;
}

void _paintRim(Canvas canvas, Rect rect, {required Color edge, Color? highlight, double line = 1}) {
  final radius = Radius.circular(rect.height / 2);
  final outer = RRect.fromRectAndRadius(rect, radius);
  canvas.drawRRect(
    outer.deflate(line / 2),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = line
      ..color = edge,
  );
  if (highlight == null) return;
  final shape = Path()..addRRect(outer);
  final crescent = Path.combine(PathOperation.difference, shape, shape.shift(Offset(0, line)));
  canvas.drawPath(crescent, Paint()..color = highlight);
}

/// CSS's `saturate()` as a colour matrix.
List<double> _saturationMatrix(double s) {
  const r = 0.213, g = 0.715, b = 0.072;
  return [
    r + (1 - r) * s, g - g * s, b - b * s, 0, 0, //
    r - r * s, g + (1 - g) * s, b - b * s, 0, 0, //
    r - r * s, g - g * s, b + (1 - b) * s, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}
