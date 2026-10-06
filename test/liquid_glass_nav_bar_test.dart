import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_nav_bar/liquid_glass_nav_bar.dart';

const _places = [
  LiquidGlassDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  LiquidGlassDestination(icon: Icons.search, label: 'Search'),
  LiquidGlassDestination(
    icon: Icons.favorite_border,
    selectedIcon: Icons.favorite,
    label: 'Saved',
    badgeCount: 3,
  ),
  LiquidGlassDestination(icon: Icons.chat_bubble_outline, label: 'Chat'),
  LiquidGlassDestination.avatar(label: 'You', initials: 'AB'),
];

const _phone = Size(402, 874);

Future<void> _pump(
  WidgetTester tester,
  Widget bar, {
  MediaQueryData? query,
  Size size = _phone,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Builder(
        builder: (context) => MediaQuery(
          data: query ?? MediaQuery.of(context),
          child: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: bar,
          ),
        ),
      ),
    ),
  );
}

/// A bar that keeps its own selection, as an app does.
class _Host extends StatefulWidget {
  const _Host({super.key, this.start = 0, this.style, this.places = _places, this.onChanged});

  final int start;
  final LiquidGlassNavBarStyle? style;
  final List<LiquidGlassDestination> places;
  final ValueChanged<int>? onChanged;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int selected = widget.start;

  @override
  Widget build(BuildContext context) => LiquidGlassNavBar(
    destinations: widget.places,
    selectedIndex: selected,
    style: widget.style,
    onSelected: (i) {
      widget.onChanged?.call(i);
      setState(() => selected = i);
    },
  );
}

Finder get _lensFinder => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_LensPainter',
);

void main() {
  testWidgets('a floating capsule: 64 high, 16 from the sides, 24 from the bottom', (tester) async {
    await _pump(tester, const _Host());
    final slot = tester.getRect(find.byType(LiquidGlassNavBar));
    expect(slot.height, LiquidGlassNavBar.slotHeight);
    expect(slot.bottom, _phone.height);
    final capsule = tester.getRect(find.byType(BackdropFilter));
    expect(capsule.height, 64);
    expect(capsule.left, 16);
    expect(capsule.right, _phone.width - 16);
    expect(_phone.height - capsule.bottom, 24);
  });

  testWidgets('the size of the capsule follows the style', (tester) async {
    await _pump(
      tester,
      const _Host(style: LiquidGlassNavBarStyle(height: 72, sideMargin: 8, bottomMargin: 12)),
    );
    final capsule = tester.getRect(find.byType(BackdropFilter));
    expect(capsule.height, 72);
    expect(capsule.left, 8);
    expect(_phone.height - capsule.bottom, 12);
  });

  group('selection', () {
    testWidgets('a tap selects; the lens slides there on a spring', (tester) async {
      var last = -1;
      await _pump(tester, _Host(onChanged: (i) => last = i));
      final start = tester.getRect(_lensFinder);
      await tester.tap(find.text('Saved'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(last, 2);
      final moving = tester.getRect(_lensFinder);
      expect(moving.left, greaterThan(start.left));
      expect(moving.center.dx, lessThan(tester.getCenter(find.text('Saved')).dx));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(_lensFinder).center.dx,
        closeTo(tester.getCenter(find.text('Saved')).dx, 1),
      );
    });

    testWidgets('a tap is a tap: the tapped item, never further', (tester) async {
      var last = -1;
      await _pump(tester, _Host(onChanged: (i) => last = i));
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(last, 1);
    });

    testWidgets('on touch-down the lens leaves for the touched item at once', (tester) async {
      var last = -1;
      await _pump(tester, _Host(onChanged: (i) => last = i));
      final start = tester.getRect(_lensFinder);
      final gesture = await tester.startGesture(tester.getCenter(find.text('You')));
      await tester.pump();
      expect(tester.getRect(_lensFinder).center.dx, greaterThan(start.center.dx + 1));
      expect(last, -1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(last, 4);
    });

    testWidgets('a touch that ends in no tap sends the lens back', (tester) async {
      await _pump(tester, const _Host());
      final start = tester.getRect(_lensFinder);
      final gesture = await tester.startGesture(tester.getCenter(find.text('Saved')));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.getRect(_lensFinder).center.dx, closeTo(start.center.dx, 0.5));
    });

    testWidgets('a tiny jitter under the touch slop stays put', (tester) async {
      var last = -1;
      await _pump(tester, _Host(onChanged: (i) => last = i));
      final gesture = await tester.startGesture(tester.getCenter(find.text('Home')));
      for (final dx in [4.0, -6.0, 5.0, -3.0]) {
        await gesture.moveBy(Offset(dx, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(last, -1);
    });

    testWidgets('a slow drag lands under the finger', (tester) async {
      var last = -1;
      await _pump(tester, _Host(onChanged: (i) => last = i));
      final from = tester.getCenter(find.text('Home'));
      final to = tester.getCenter(find.text('Chat'));
      final gesture = await tester.startGesture(from);
      // About 300 a second, a frame at a time: no momentum.
      const steps = 50;
      for (var i = 0; i < steps; i++) {
        await gesture.moveBy(
          Offset((to.dx - from.dx) / steps, 0),
          timeStamp: Duration(milliseconds: 16 * i),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up(timeStamp: const Duration(milliseconds: 16 * steps + 100));
      await tester.pumpAndSettle();
      expect(last, 3);
    });

    testWidgets('a drag started away from the lens brings it under the finger', (tester) async {
      var last = -1;
      await _pump(tester, _Host(onChanged: (i) => last = i));
      final gesture = await tester.startGesture(tester.getCenter(find.text('Saved')));
      await gesture.moveBy(const Offset(30, 0));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        tester.getRect(_lensFinder).center.dx,
        closeTo(tester.getCenter(find.text('Saved')).dx + 30, 6),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(last, 2);
    });

    testWidgets('a fast short fling goes at most one item past where it is let go', (tester) async {
      for (final speed in [1200.0, 3000.0, 8000.0]) {
        var selected = 0;
        await _pump(tester, _Host(key: ValueKey(speed), onChanged: (i) => selected = i));
        // A short flick from Home: let go over Home, so it lands on Home or Search.
        await tester.flingFrom(tester.getCenter(find.text('Home')), const Offset(60, 0), speed);
        await tester.pumpAndSettle();
        expect(selected, lessThanOrEqualTo(1), reason: '$speed');
        // Fast enough, the momentum carries it that one item.
        if (speed >= 3000) {
          expect(selected, 1, reason: '$speed');
        }
      }
    });

    testWidgets('a slow flick under 900 px/s has no momentum', (tester) async {
      var selected = 0;
      await _pump(tester, _Host(onChanged: (i) => selected = i));
      await tester.flingFrom(tester.getCenter(find.text('Home')), const Offset(30, 0), 600);
      await tester.pumpAndSettle();
      expect(selected, 0);
    });
  });

  group('the lens as a drop of glass', () {
    Rect capsule(WidgetTester tester) => tester.getRect(find.byType(BackdropFilter));

    testWidgets('a press grows the capsule and the item under the lens; release settles', (
      tester,
    ) async {
      await _pump(tester, const _Host());
      final rest = capsule(tester);
      final restIcon = tester.getRect(find.byIcon(Icons.home));
      final gesture = await tester.startGesture(tester.getCenter(find.text('Home')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(capsule(tester).width, closeTo(rest.width * (1 + LiquidGlassNavBar.pressGrow), 0.5));
      expect(capsule(tester).center.dx, closeTo(rest.center.dx, 0.5));
      expect(tester.getRect(find.byIcon(Icons.home)).width, greaterThan(restIcon.width * 1.1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(capsule(tester).width, closeTo(rest.width, 0.5));
      expect(tester.getRect(find.byIcon(Icons.home)).width, closeTo(restIcon.width, 0.5));
    });

    testWidgets('no ink: the lens is the only feedback', (tester) async {
      await _pump(tester, const _Host());
      for (final ink in tester.widgetList<InkResponse>(find.byType(InkResponse))) {
        expect(ink.splashFactory, NoSplash.splashFactory);
        expect(ink.highlightColor, Colors.transparent);
        for (final state in [WidgetState.pressed, WidgetState.hovered, WidgetState.focused]) {
          expect(ink.overlayColor?.resolve({state}), Colors.transparent);
        }
      }
    });

    for (final width in [320.0, 402.0]) {
      testWidgets('at $width wide the lens is centred on every item, concentric at the ends', (
        tester,
      ) async {
        for (var i = 0; i < _places.length; i++) {
          await _pump(
            tester,
            LiquidGlassNavBar(
              key: ValueKey(i),
              destinations: _places,
              selectedIndex: i,
              // Ahem, the test font, is as wide as it is high: small, so no label is cut.
              style: const LiquidGlassNavBarStyle(
                labelStyle: TextStyle(fontSize: 5),
                selectedLabelStyle: TextStyle(fontSize: 5),
              ),
              onSelected: (_) {},
            ),
            size: Size(width, 874),
          );
          final lens = tester.getRect(_lensFinder);
          final d = _places[i];
          final glyph = d.isAvatar
              ? find.text(d.avatarInitials!)
              : find.byIcon(d.selectedIcon ?? d.icon!);
          expect(lens.center.dx, closeTo(tester.getCenter(glyph).dx, 0.5), reason: d.label);
          expect(lens.center.dx, closeTo(tester.getCenter(find.text(d.label)).dx, 0.5));
          // The painted lens is its slot plus 6 on each side.
          expect(lens.width, closeTo((width - 32 - 2 * LiquidGlassNavBar.sideInset) / 5, 0.01));
          const extra = LiquidGlassNavBar.lensExtra / 2;
          final painted = Rect.fromLTRB(
            lens.left - extra,
            lens.top,
            lens.right + extra,
            lens.bottom,
          );
          final capsule = tester.getRect(find.byType(BackdropFilter));
          final top = painted.top - capsule.top;
          expect(top, closeTo(LiquidGlassNavBar.inset, 0.5));
          expect(capsule.bottom - painted.bottom, closeTo(top, 0.5));
          if (i == 0) expect(painted.left - capsule.left, closeTo(top, 0.5), reason: 'first');
          if (i == _places.length - 1) {
            expect(capsule.right - painted.right, closeTo(top, 0.5), reason: 'last');
          }
          // Radius 28 against the capsule's 32: parallel curves.
          expect(painted.height / 2, closeTo(capsule.height / 2 - top, 0.5));
        }
      });
    }
  });

  group('labels', () {
    // Ahem, the test font, is as wide as it is high: 5 px a character at size 5.
    const style = TextStyle(fontSize: 5);
    String shorten(String label, double room) =>
        LiquidGlassNavBar.shortenLabel(label, style, room, TextScaler.noScaling);

    test('a label over 9 characters is shortened with a period, whatever the room', () {
      expect(shorten('Notifications', 400), 'Notific.');
      expect(shorten('Notifications', 20), 'Not.');
    });

    test('9 characters or fewer are kept whole when they fit, cut when they do not', () {
      expect(shorten('Dashboard', 45), 'Dashboard');
      expect(shorten('Dashboard', 35), 'Dashbo.');
      expect(shorten('Home', 40), 'Home');
    });

    test('cut after a letter, never after a hyphen or a space', () {
      expect(shorten('Check-in', 30), 'Check.');
      expect(shorten('Sign out', 25), 'Sign.');
    });

    testWidgets('on the bar a long label reads shortened and the full word is spoken', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        LiquidGlassNavBar(
          destinations: const [
            LiquidGlassDestination(icon: Icons.home, label: 'Home'),
            LiquidGlassDestination(icon: Icons.notifications, label: 'Notifications'),
          ],
          selectedIndex: 1,
          style: const LiquidGlassNavBarStyle(labelStyle: style, selectedLabelStyle: style),
          onSelected: (_) {},
        ),
      );
      expect(find.text('Notific.'), findsOneWidget);
      expect(find.text('Notifications'), findsNothing);
      expect(tester.getSemantics(find.bySemanticsLabel('Notifications')).label, 'Notifications');
      semantics.dispose();
    });
  });

  group('the opaque fallback', () {
    testWidgets('the glass blurs: a BackdropFilter and no opaque capsule', (tester) async {
      await _pump(tester, const _Host());
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('opaque when the platform asks for fewer effects', (tester) async {
      late bool opaque;
      Future<void> check(MediaQueryData query, {LiquidGlassPolicy? policy}) async {
        final probe = Builder(
          builder: (context) {
            opaque = LiquidGlassNavBar.isOpaque(context);
            return const SizedBox();
          },
        );
        await tester.pumpWidget(
          MediaQuery(
            data: query,
            child: policy == null
                ? probe
                : LiquidGlassPolicy(
                    blurSupported: policy.blurSupported,
                    reduceTransparency: policy.reduceTransparency,
                    reduceMotion: policy.reduceMotion,
                    child: probe,
                  ),
          ),
        );
      }

      const none = SizedBox();
      await check(const MediaQueryData());
      expect(opaque, isFalse);
      await check(const MediaQueryData(highContrast: true));
      expect(opaque, isTrue);
      await check(const MediaQueryData(disableAnimations: true));
      expect(opaque, isTrue);
      await check(
        const MediaQueryData(),
        policy: const LiquidGlassPolicy(blurSupported: false, child: none),
      );
      expect(opaque, isTrue);
      await check(
        const MediaQueryData(),
        policy: const LiquidGlassPolicy(reduceTransparency: true, child: none),
      );
      expect(opaque, isTrue);
      await check(
        const MediaQueryData(),
        policy: const LiquidGlassPolicy(reduceMotion: true, child: none),
      );
      expect(opaque, isTrue);
    });

    testWidgets('a policy without blur draws the opaque capsule with no BackdropFilter', (
      tester,
    ) async {
      await _pump(tester, const LiquidGlassPolicy(blurSupported: false, child: _Host()));
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('with reduced motion the lens jumps and nothing swells', (tester) async {
      await _pump(
        tester,
        const _Host(),
        query: const MediaQueryData(size: _phone, disableAnimations: true),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      final restIcon = tester.getRect(find.byIcon(Icons.home));
      final press = await tester.startGesture(tester.getCenter(find.text('Home')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(find.byIcon(Icons.home)), restIcon);
      await press.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pump();
      expect(
        tester.getRect(_lensFinder).center.dx,
        closeTo(tester.getCenter(find.text('Chat')).dx, 1),
      );
    });
  });

  group('accessibility', () {
    testWidgets('every item is a button with its selected state; the count is spoken', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, const _Host(start: 1));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Search')),
        isSemantics(label: 'Search', isButton: true, isSelected: true, hasTapAction: true),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Saved')).value, '3');
      semantics.dispose();
    });

    testWidgets('the focus ring shows from the keyboard, never on touch', (tester) async {
      await _pump(tester, const _Host());
      Finder ring() => find.descendant(
        of: find.byType(LiquidGlassNavBar),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is ShapeDecoration &&
              (w.decoration as ShapeDecoration).shape is StadiumBorder &&
              ((w.decoration as ShapeDecoration).shape as StadiumBorder).side != BorderSide.none &&
              ((w.decoration as ShapeDecoration).shape as StadiumBorder).side.width ==
                  LiquidGlassNavBar.focusRingWidth &&
              (w.decoration as ShapeDecoration).color == null,
        ),
      );
      final before = ring().evaluate().length;
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(ring().evaluate().length, before);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.traditional);
      expect(ring().evaluate().length, before + 1);
    });
  });

  group('the style', () {
    testWidgets('colours and icons follow the style, the selected one its selected icon', (
      tester,
    ) async {
      const accent = Color(0xFFFF6D00);
      await _pump(
        tester,
        const _Host(
          style: LiquidGlassNavBarStyle(selectedColor: accent, unselectedColor: Colors.grey),
        ),
      );
      expect(tester.widget<Icon>(find.byIcon(Icons.home)).color, accent);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
      expect(tester.widget<Icon>(find.byIcon(Icons.search)).color, Colors.grey);
    });

    testWidgets('light and dark have their own defaults', (tester) async {
      const light = LiquidGlassNavBarStyle.light();
      const dark = LiquidGlassNavBarStyle.dark();
      expect(light.unselectedColor, isNot(dark.unselectedColor));
      expect(LiquidGlassNavBarStyle.resolve(Brightness.dark).glassColor, dark.glassColor);
      await _pump(tester, const _Host(), brightness: Brightness.dark);
      expect(tester.widget<Icon>(find.byIcon(Icons.search)).color, dark.unselectedColor);
    });

    test('merge keeps what the other leaves null', () {
      final merged = const LiquidGlassNavBarStyle.light().merge(
        const LiquidGlassNavBarStyle(blurSigma: 5),
      );
      expect(merged.blurSigma, 5);
      expect(merged.height, 64);
      expect(const LiquidGlassNavBarStyle.light().copyWith(height: 50).height, 50);
    });

    testWidgets('any widget is an icon, with its own selected widget', (tester) async {
      await _pump(
        tester,
        const _Host(
          places: [
            LiquidGlassDestination.widget(
              icon: SizedBox(key: ValueKey('plain'), width: 10, height: 10),
              selectedIcon: SizedBox(key: ValueKey('filled'), width: 10, height: 10),
              label: 'One',
            ),
            LiquidGlassDestination.widget(icon: Icon(Icons.star), label: 'Two'),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('filled')), findsOneWidget);
      expect(find.byKey(const ValueKey('plain')), findsNothing);
      expect(tester.getSize(find.byIcon(Icons.star)).width, lessThanOrEqualTo(24));
    });

    testWidgets('the badge caps at 99+ and the avatar shows its initials', (tester) async {
      await _pump(
        tester,
        const _Host(
          places: [
            LiquidGlassDestination(icon: Icons.home, label: 'Home', badgeCount: 120),
            LiquidGlassDestination.avatar(label: 'Me', initials: 'ZK'),
          ],
        ),
      );
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('ZK'), findsOneWidget);
    });
  });

  group('goldens', () {
    for (final brightness in Brightness.values) {
      testWidgets('over a colourful backdrop, ${brightness.name}', skip: !Platform.isMacOS, (
        tester,
      ) async {
        tester.view.physicalSize = const Size(402, 200) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              extendBody: true,
              body: Row(
                children: [
                  for (final c in [
                    Colors.pink,
                    Colors.orange,
                    Colors.teal,
                    Colors.indigo,
                    Colors.amber,
                  ])
                    Expanded(
                      child: ColoredBox(color: c, child: const SizedBox.expand()),
                    ),
                ],
              ),
              bottomNavigationBar: LiquidGlassNavBar(
                destinations: _places,
                selectedIndex: 1,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/nav_bar.${brightness.name}.png'),
        );
      });
    }
  });
}
