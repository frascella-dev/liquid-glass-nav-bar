import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Whether the demo plays itself (`--dart-define=AUTOPLAY=true`): a script of taps, drags
/// and flings sent as real pointer events, used to record the README's video.
const autoplay = bool.fromEnvironment('AUTOPLAY');

/// Plays a short choreography on the bar found by [barKey], drawing a dot where the
/// finger is, and calls [onDark] and [onOpaque] for the settings it shows.
class Autoplayer extends StatefulWidget {
  const Autoplayer({
    super.key,
    required this.barKey,
    required this.child,
    required this.onDark,
    required this.onOpaque,
  });

  final GlobalKey barKey;
  final Widget child;
  final ValueChanged<bool> onDark;
  final ValueChanged<bool> onOpaque;

  @override
  State<Autoplayer> createState() => _AutoplayerState();
}

class _AutoplayerState extends State<Autoplayer> {
  final _finger = ValueNotifier<Offset?>(null);
  final _clock = Stopwatch()..start();
  var _id = 1000;
  var _running = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _running = false;
    _finger.dispose();
    super.dispose();
  }

  Rect get _bar {
    final box = widget.barKey.currentContext!.findRenderObject()! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// The centre of the [i]-th of five items.
  Offset _item(int i) {
    final bar = _bar;
    final itemWidth = (bar.width - 32 - 20) / 5;
    return Offset(
      bar.left + 16 + 10 + (i + 0.5) * itemWidth,
      bar.bottom - 24 - 32,
    );
  }

  Future<void> _wait(int ms) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  /// A finger from [from] to [to] in [ms], through [steps] move events.
  Future<void> _drag(
    Offset from,
    Offset to, {
    int ms = 600,
    bool hold = false,
  }) async {
    final binding = GestureBinding.instance;
    final id = _id++;
    final steps = (ms / 8).round();
    var last = from;
    binding.handlePointerEvent(
      PointerAddedEvent(timeStamp: _clock.elapsed, pointer: id, position: from),
    );
    binding.handlePointerEvent(
      PointerDownEvent(timeStamp: _clock.elapsed, pointer: id, position: from),
    );
    _finger.value = from;
    for (var i = 1; i <= steps && _running; i++) {
      await _wait(8);
      final t = i / steps;
      final p = Offset.lerp(from, to, Curves.easeInOut.transform(t))!;
      binding.handlePointerEvent(
        PointerMoveEvent(
          timeStamp: _clock.elapsed,
          pointer: id,
          position: p,
          delta: p - last,
        ),
      );
      last = p;
      _finger.value = p;
    }
    if (hold) await _wait(250);
    binding.handlePointerEvent(
      PointerUpEvent(timeStamp: _clock.elapsed, pointer: id, position: last),
    );
    _finger.value = null;
  }

  Future<void> _tap(Offset at) async {
    final binding = GestureBinding.instance;
    final id = _id++;
    binding.handlePointerEvent(
      PointerAddedEvent(timeStamp: _clock.elapsed, pointer: id, position: at),
    );
    binding.handlePointerEvent(
      PointerDownEvent(timeStamp: _clock.elapsed, pointer: id, position: at),
    );
    _finger.value = at;
    await _wait(140);
    binding.handlePointerEvent(
      PointerUpEvent(timeStamp: _clock.elapsed, pointer: id, position: at),
    );
    _finger.value = null;
  }

  Future<void> _scroll(double dy, {int ms = 700}) async {
    final size = MediaQuery.sizeOf(context);
    final x = size.width / 2;
    final y = size.height * 0.5;
    await _drag(Offset(x, y + dy / 2), Offset(x, y - dy / 2), ms: ms);
  }

  Future<void> _play() async {
    await _wait(1500);
    while (_running && mounted) {
      // The glass over the content, scrolled under it.
      await _scroll(380);
      await _wait(250);
      await _scroll(380);
      await _wait(500);
      // Taps: the lens leaves on touch-down, swells, slides on a spring.
      await _tap(_item(1));
      await _wait(1100);
      await _tap(_item(3));
      await _wait(1100);
      await _tap(_item(0));
      await _wait(1100);
      // A slow drag: the lens follows the finger, the item under it lit.
      await _drag(_item(0), _item(4), ms: 1500, hold: true);
      await _wait(1100);
      await _drag(_item(4), _item(1), ms: 1100, hold: true);
      await _wait(900);
      // A fling: faster than 900 px/s, one item further at most.
      await _drag(_item(1), _item(1) + const Offset(70, 0), ms: 70);
      await _wait(1200);
      await _drag(_item(2), _item(2) - const Offset(80, 0), ms: 80);
      await _wait(1200);
      // Dark, and back.
      widget.onDark(true);
      await _wait(600);
      await _scroll(-420);
      await _wait(300);
      await _tap(_item(2));
      await _wait(1100);
      await _scroll(380);
      await _wait(700);
      // The opaque fallback.
      await _tap(_item(4));
      await _wait(900);
      widget.onOpaque(true);
      await _wait(1200);
      await _tap(_item(0));
      await _wait(1100);
      widget.onOpaque(false);
      widget.onDark(false);
      await _wait(1200);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: ValueListenableBuilder<Offset?>(
            valueListenable: _finger,
            builder: (context, p, _) => p == null
                ? const SizedBox.shrink()
                : Stack(
                    children: [
                      Positioned(
                        left: p.dx - 18,
                        top: p.dy - 18,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.35),
                            border: Border.all(
                              color: Colors.black26,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
