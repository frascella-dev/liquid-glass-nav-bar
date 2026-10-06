import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_nav_bar/liquid_glass_nav_bar.dart';

import 'autoplay.dart';

void main() => runApp(const DemoApp());

/// The accents the demo lets you try; each one is a [LiquidGlassNavBarStyle].
const _accents = <String, Color>{
  'Blue': Color(0xFF0A84FF),
  'Coral': Color(0xFFFF5A4D),
  'Mint': Color(0xFF12B886),
  'Violet': Color(0xFF7C4DFF),
};

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  Brightness brightness = Brightness.light;
  bool opaque = false;
  String accent = 'Blue';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'liquid_glass_nav_bar',
      theme: ThemeData(
        brightness: brightness,
        colorSchemeSeed: _accents[accent],
        useMaterial3: true,
      ),
      home: Home(
        brightness: brightness,
        opaque: opaque,
        accent: accent,
        onBrightness: (b) => setState(() => brightness = b),
        onOpaque: (v) => setState(() => opaque = v),
        onAccent: (a) => setState(() => accent = a),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.brightness,
    required this.opaque,
    required this.accent,
    required this.onBrightness,
    required this.onOpaque,
    required this.onAccent,
  });

  final Brightness brightness;
  final bool opaque;
  final String accent;
  final ValueChanged<Brightness> onBrightness;
  final ValueChanged<bool> onOpaque;
  final ValueChanged<String> onAccent;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int index = 0;
  final barKey = GlobalKey();

  static const places = [
    LiquidGlassDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Explore',
    ),
    LiquidGlassDestination(
      icon: Icons.search,
      selectedIcon: Icons.search,
      label: 'Discover',
    ),
    LiquidGlassDestination(
      icon: Icons.bookmark_border,
      selectedIcon: Icons.bookmark,
      label: 'Saved',
    ),
    LiquidGlassDestination(
      icon: Icons.notifications_none,
      selectedIcon: Icons.notifications,
      label: 'Notifications',
      badgeCount: 3,
    ),
    LiquidGlassDestination.avatar(label: 'You', initials: 'LG'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accents[widget.accent]!;
    final dark = widget.brightness == Brightness.dark;
    final style = LiquidGlassNavBarStyle(
      selectedColor: dark ? Color.lerp(accent, Colors.white, 0.35) : accent,
      lensColor: accent.withValues(alpha: dark ? 0.30 : 0.18),
      lensEdgeColor: accent.withValues(alpha: dark ? 0.45 : 0.30),
      opaqueLensColor: Color.lerp(
        dark ? const Color(0xFF2C2C2E) : Colors.white,
        accent,
        0.18,
      ),
    );
    final pages = [
      Feed(
        title: 'Explore',
        brightness: widget.brightness,
        onBrightness: widget.onBrightness,
        big: true,
      ),
      Feed(
        title: 'Discover',
        brightness: widget.brightness,
        onBrightness: widget.onBrightness,
      ),
      Feed(
        title: 'Saved',
        brightness: widget.brightness,
        onBrightness: widget.onBrightness,
        offset: 5,
      ),
      Feed(
        title: 'Notifications',
        brightness: widget.brightness,
        onBrightness: widget.onBrightness,
        offset: 9,
      ),
      Settings(
        brightness: widget.brightness,
        opaque: widget.opaque,
        accent: widget.accent,
        onBrightness: widget.onBrightness,
        onOpaque: widget.onOpaque,
        onAccent: widget.onAccent,
      ),
    ];
    final app = LiquidGlassPolicy(
      // Here the facts are a switch; in an app they come from the platform.
      reduceTransparency: widget.opaque,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: LiquidGlassNavBar(
          key: barKey,
          destinations: places,
          selectedIndex: index,
          onSelected: (i) => setState(() => index = i),
          style: style,
        ),
      ),
    );
    if (!autoplay) return app;
    return Autoplayer(
      barKey: barKey,
      onDark: (v) =>
          widget.onBrightness(v ? Brightness.dark : Brightness.light),
      onOpaque: widget.onOpaque,
      child: app,
    );
  }
}

/// A scrolling feed of art cards: the colour the glass blurs.
class Feed extends StatelessWidget {
  const Feed({
    super.key,
    required this.title,
    required this.brightness,
    required this.onBrightness,
    this.offset = 0,
    this.big = false,
  });

  final String title;
  final Brightness brightness;
  final ValueChanged<Brightness> onBrightness;
  final int offset;
  final bool big;

  static const _names = [
    'Golden hour',
    'Blue ridge',
    'Rose desert',
    'Night harbour',
    'Mint valley',
    'Violet dusk',
    'Ember coast',
    'Glacier light',
    'Plum meadow',
    'Citrus bay',
    'Slate morning',
    'Lagoon',
  ];

  @override
  Widget build(BuildContext context) {
    final bottom =
        LiquidGlassNavBar.slotHeight + MediaQuery.paddingOf(context).bottom;
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Light or dark',
              icon: Icon(
                brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () => onBrightness(
                brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, bottom + 16),
          sliver: SliverList.separated(
            itemCount: 12,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final n = i + offset;
              return ArtCard(
                seed: n,
                title: _names[n % _names.length],
                tall: big && i % 3 == 0,
              );
            },
          ),
        ),
      ],
    );
  }
}

class ArtCard extends StatelessWidget {
  const ArtCard({
    super.key,
    required this.seed,
    required this.title,
    this.tall = false,
  });

  final int seed;
  final String title;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: tall ? 0.95 : 1.6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: ArtPainter(seed)),
            Positioned(
              left: 16,
              bottom: 14,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(blurRadius: 12, color: Colors.black38),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A procedural landscape: a sky gradient, a sun and three layers of hills. Vivid on
/// purpose, so the blur and the saturation of the glass have something to show.
class ArtPainter extends CustomPainter {
  const ArtPainter(this.seed);

  final int seed;

  static const _skies = [
    [Color(0xFFFFB347), Color(0xFFFF3D7F)],
    [Color(0xFF38BDF8), Color(0xFF6366F1)],
    [Color(0xFFFDE68A), Color(0xFFFB7185)],
    [Color(0xFF312E81), Color(0xFF0EA5E9)],
    [Color(0xFFA7F3D0), Color(0xFF14B8A6)],
    [Color(0xFFC4B5FD), Color(0xFFEC4899)],
    [Color(0xFFFCA5A5), Color(0xFFF59E0B)],
    [Color(0xFFBAE6FD), Color(0xFF818CF8)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sky = _skies[seed % _skies.length];
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: sky,
        ).createShader(rect),
    );
    final r = math.Random(seed * 7 + 3);
    canvas.drawCircle(
      Offset(
        size.width * (0.2 + 0.6 * r.nextDouble()),
        size.height * (0.22 + 0.14 * r.nextDouble()),
      ),
      size.shortestSide * (0.12 + 0.06 * r.nextDouble()),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    for (var layer = 0; layer < 3; layer++) {
      final base = size.height * (0.52 + layer * 0.16);
      final amp = size.height * (0.12 - layer * 0.02);
      final phase = r.nextDouble() * math.pi * 2;
      final freq = 1.2 + r.nextDouble() * 1.4;
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 4) {
        final t = x / size.width * math.pi * 2 * freq + phase;
        path.lineTo(
          x,
          base + math.sin(t) * amp + math.sin(t * 2.3) * amp * 0.35,
        );
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            sky[1],
            const Color(0xFF0B1020),
            0.25 + layer * 0.25,
          )!,
      );
    }
  }

  @override
  bool shouldRepaint(ArtPainter old) => old.seed != seed;
}

class Settings extends StatelessWidget {
  const Settings({
    super.key,
    required this.brightness,
    required this.opaque,
    required this.accent,
    required this.onBrightness,
    required this.onOpaque,
    required this.onAccent,
  });

  final Brightness brightness;
  final bool opaque;
  final String accent;
  final ValueChanged<Brightness> onBrightness;
  final ValueChanged<bool> onOpaque;
  final ValueChanged<String> onAccent;

  @override
  Widget build(BuildContext context) {
    final bottom =
        LiquidGlassNavBar.slotHeight + MediaQuery.paddingOf(context).bottom;
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('You')),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
          sliver: SliverList.list(
            children: [
              SwitchListTile(
                title: const Text('Dark'),
                subtitle: const Text(
                  'The bar picks its glass for the brightness',
                ),
                value: brightness == Brightness.dark,
                onChanged: (v) =>
                    onBrightness(v ? Brightness.dark : Brightness.light),
              ),
              SwitchListTile(
                title: const Text('Reduce transparency'),
                subtitle: const Text(
                  'The opaque fallback, as on Android below 12 or with iOS Reduce Transparency',
                ),
                value: opaque,
                onChanged: onOpaque,
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Accent'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final e in _accents.entries)
                      ChoiceChip(
                        label: Text(e.key),
                        avatar: CircleAvatar(backgroundColor: e.value),
                        selected: accent == e.key,
                        onSelected: (_) => onAccent(e.key),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ArtCard(seed: i + 2, title: 'Backdrop ${i + 1}'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
