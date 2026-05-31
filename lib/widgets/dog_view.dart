import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/pet_catalog.dart';
import '../data/pet_data.dart';
import '../models/dog_breed.dart';
import '../models/pet_items.dart';

const double _tau = 6.283185307179586;

/// A fully procedural, animated cartoon dog. No image assets required.
///
/// Idle animation layers (breathing, body bob, tail wag, blinking, ear
/// twitch and a gentle side-to-side sway) are combined to read as natural,
/// lively movement. Tapping — or bumping [celebrateTick] — triggers a happy
/// hop.
class DogView extends StatefulWidget {
  final DogBreed breed;
  final DogMood mood;
  final Set<String> equipped;

  /// Change this value to trigger a one-shot happy hop (e.g. after feeding).
  final int celebrateTick;
  final VoidCallback? onTap;

  const DogView({
    super.key,
    required this.breed,
    required this.mood,
    this.equipped = const {},
    this.celebrateTick = 0,
    this.onTap,
  });

  @override
  State<DogView> createState() => _DogViewState();
}

class _DogViewState extends State<DogView> with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _hop;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _hop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void didUpdateWidget(covariant DogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.celebrateTick != widget.celebrateTick) {
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _hop.dispose();
    super.dispose();
  }

  void _handleTap() {
    _hop.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _hop]),
        builder: (context, _) {
          final v = _idle.value;

          // Use integer cycle counts so the loop is seamless.
          final breath = 1 + 0.018 * math.sin(_tau * 3 * v);
          final bob = -3.0 * math.sin(_tau * 2 * v);
          var tailWag = 0.5 * math.sin(_tau * 12 * v);
          final sway = 0.03 * math.sin(_tau * v);
          final drift = 7.0 * math.sin(_tau * v);

          // Blink: brief closures twice per loop.
          double blink = 0;
          for (final c in const [0.32, 0.80]) {
            final d = (v - c).abs();
            const w = 0.035;
            if (d < w) blink = math.max(blink, 1 - d / w);
          }

          // Ear twitch: one quick flick per loop.
          double earTwitch = 0;
          {
            final d = (v - 0.55).abs();
            const w = 0.05;
            if (d < w) earTwitch = 1 - d / w;
          }

          // Hop (tap / celebrate): up then down.
          final hp = _hop.value;
          final hop = -26.0 * math.sin(math.pi * hp);
          final excited = hp > 0.05 && hp < 0.95;
          if (excited) {
            tailWag += 0.45 * math.sin(_tau * 22 * v);
          }

          return CustomPaint(
            size: Size.infinite,
            painter: DogPainter(
              breed: widget.breed,
              mood: excited ? DogMood.happy : widget.mood,
              equipped: widget.equipped,
              breath: breath,
              bob: bob + hop,
              tailWag: tailWag,
              sway: sway,
              drift: drift,
              blink: blink,
              earTwitch: earTwitch,
            ),
          );
        },
      ),
    );
  }
}

/// Paints a sitting, front-facing cartoon dog inside a fixed design box that
/// is uniformly scaled to fit the available size.
class DogPainter extends CustomPainter {
  final DogBreed breed;
  final DogMood mood;
  final Set<String> equipped;
  final double breath;
  final double bob;
  final double tailWag;
  final double sway;
  final double drift;
  final double blink;
  final double earTwitch;

  DogPainter({
    required this.breed,
    required this.mood,
    required this.equipped,
    required this.breath,
    required this.bob,
    required this.tailWag,
    required this.sway,
    required this.drift,
    required this.blink,
    required this.earTwitch,
  });

  // Design box. Origin is the box centre; dog head sits high, feet near +110.
  static const double _dw = 200;
  static const double _dh = 240;

  Paint _fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Color _darker(Color c, double a) => Color.lerp(c, Colors.black, a)!;
  Color _lighter(Color c, double a) => Color.lerp(c, Colors.white, a)!;
  Color get _earInner => const Color(0xFFEBB1A8);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _dw, size.height / _dh);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    // Ground shadow stays on the floor; it shrinks a little as the dog rises.
    final ss = (1 + bob / 70).clamp(0.7, 1.05);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 116), width: 120 * ss, height: 20 * ss),
      _fill(Colors.black.withValues(alpha: 0.12 * ss)),
    );

    // Animate the dog around a pivot near its feet.
    canvas.translate(drift, bob);
    canvas.translate(0, 100);
    canvas.rotate(sway);
    canvas.scale(1, breath);
    canvas.translate(0, -100);

    _drawTail(canvas);
    _drawBody(canvas);
    _drawHead(canvas);
    _drawAccessories(canvas);

    canvas.restore();
  }

  // --------------------------------------------------------------- body
  void _drawBody(Canvas canvas) {
    final p = breed.primary;
    final bottomHalf = breed.body == DogBodyShape.short ? 60.0 : 64.0;

    final body = Path()
      ..moveTo(-34, 0)
      ..cubicTo(-58, 20, -70, 70, -bottomHalf, 100)
      ..quadraticBezierTo(-bottomHalf + 4, 112, -40, 112)
      ..lineTo(40, 112)
      ..quadraticBezierTo(bottomHalf - 4, 112, bottomHalf, 100)
      ..cubicTo(70, 70, 58, 20, 34, 0)
      ..quadraticBezierTo(0, -14, -34, 0)
      ..close();
    canvas.drawPath(body, _fill(p));

    // German Shepherd dark saddle over the back.
    if (breed.id == 'gsd') {
      final saddle = Path()
        ..moveTo(-42, 2)
        ..cubicTo(-58, 30, -56, 72, -44, 96)
        ..quadraticBezierTo(0, 78, 44, 96)
        ..cubicTo(56, 72, 58, 30, 42, 2)
        ..quadraticBezierTo(0, 18, -42, 2)
        ..close();
      canvas.drawPath(saddle, _fill(breed.patch));
    }

    // Chest / belly blaze.
    final belly = Path()
      ..moveTo(0, 8)
      ..cubicTo(-26, 30, -30, 80, -18, 104)
      ..quadraticBezierTo(0, 112, 18, 104)
      ..cubicTo(30, 80, 26, 30, 0, 8)
      ..close();
    canvas.drawPath(belly, _fill(breed.secondary));

    // Front legs + paws.
    final pawColor = breed.id == 'dachshund' ? breed.secondary : breed.secondary;
    for (final dx in const [-30.0, 30.0]) {
      final leg = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 15, 60, 30, 52),
        const Radius.circular(15),
      );
      canvas.drawRRect(leg, _fill(p));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(dx, 110), width: 34, height: 20),
        _fill(pawColor),
      );
      canvas.drawLine(Offset(dx - 5, 104), Offset(dx - 5, 114),
          _stroke(_darker(pawColor, 0.18), 2));
      canvas.drawLine(Offset(dx + 5, 104), Offset(dx + 5, 114),
          _stroke(_darker(pawColor, 0.18), 2));
    }

    if (breed.curlyCoat) {
      // Shoulder fluff for the poodle.
      for (final dx in const [-46.0, -30.0, 30.0, 46.0]) {
        canvas.drawCircle(Offset(dx, 18), 14, _fill(p));
      }
    }
  }

  // --------------------------------------------------------------- tail
  void _drawTail(Canvas canvas) {
    canvas.save();
    canvas.translate(58, 46);
    canvas.rotate(-0.5 + tailWag);
    if (breed.curlTail) {
      final path = Path()
        ..moveTo(0, 0)
        ..cubicTo(36, -6, 48, -42, 18, -50)
        ..cubicTo(0, -54, 2, -34, 18, -32);
      canvas.drawPath(path, _stroke(breed.primary, 18));
    } else {
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(40, -6, 54, -42);
      canvas.drawPath(path, _stroke(breed.primary, 16));
    }
    canvas.restore();
  }

  // --------------------------------------------------------------- head
  void _drawHead(Canvas canvas) {
    const center = Offset(0, -55);
    const r = 56.0;

    if (breed.ear != DogEar.floppy) _drawEars(canvas);
    canvas.drawCircle(center, r, _fill(breed.primary));
    if (breed.curlyCoat) _drawCurls(canvas, center, r);
    _drawFaceMarkings(canvas, center, r);
    if (breed.ear == DogEar.floppy) _drawEars(canvas);
    _drawMuzzle(canvas, center, r);
    _drawEyes(canvas, center);
    _drawBrows(canvas, center);
    if (mood == DogMood.happy) {
      for (final side in const [-1.0, 1.0]) {
        canvas.drawCircle(Offset(center.dx + side * 34, center.dy + 12), 8,
            _fill(const Color(0xFFF3A9B0).withValues(alpha: 0.5)));
      }
    }
  }

  void _drawCurls(Canvas canvas, Offset c, double r) {
    final p = breed.primary;
    for (double a = -math.pi + 0.2; a <= 0.2; a += 0.5) {
      final pos = Offset(c.dx + math.cos(a) * (r - 4), c.dy + math.sin(a) * (r - 4));
      canvas.drawCircle(pos, 12, _fill(p));
    }
  }

  void _drawFaceMarkings(Canvas canvas, Offset c, double r) {
    if (!breed.faceMask) return;
    // Lighter lower face.
    final lower = Path()
      ..moveTo(c.dx - r * 0.7, c.dy + 4)
      ..quadraticBezierTo(c.dx, c.dy - 8, c.dx + r * 0.7, c.dy + 4)
      ..quadraticBezierTo(c.dx + r * 0.5, c.dy + r * 0.95, c.dx, c.dy + r * 0.98)
      ..quadraticBezierTo(c.dx - r * 0.5, c.dy + r * 0.95, c.dx - r * 0.7, c.dy + 4)
      ..close();
    canvas.drawPath(lower, _fill(breed.secondary));
    // Forehead blaze.
    final blaze = Path()
      ..moveTo(c.dx - 9, c.dy + 4)
      ..quadraticBezierTo(c.dx, c.dy - r * 0.85, c.dx + 9, c.dy + 4)
      ..quadraticBezierTo(c.dx, c.dy + 10, c.dx - 9, c.dy + 4)
      ..close();
    canvas.drawPath(blaze, _fill(breed.secondary));
  }

  void _drawEars(Canvas canvas) {
    const c = Offset(0, -55);
    final p = breed.primary;
    final tw = earTwitch * 0.12;
    final droop = mood == DogMood.sad ? 0.18 : 0.0;

    switch (breed.ear) {
      case DogEar.erect:
        final big = breed.id == 'gsd' || breed.id == 'corgi';
        final h = big ? 70.0 : 54.0;
        final wdt = big ? 40.0 : 34.0;
        for (final side in const [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(c.dx + side * 34, c.dy - 34);
          canvas.rotate(side * (0.15 + tw + droop));
          final ear = Path()
            ..moveTo(-wdt / 2, 10)
            ..quadraticBezierTo(-wdt / 2 - 4, -h * 0.5, 0, -h)
            ..quadraticBezierTo(wdt / 2 + 4, -h * 0.5, wdt / 2, 10)
            ..close();
          canvas.drawPath(ear, _fill(p));
          final inner = Path()
            ..moveTo(-wdt / 2 + 6, 6)
            ..quadraticBezierTo(-6, -h * 0.45, 0, -h + 14)
            ..quadraticBezierTo(6, -h * 0.45, wdt / 2 - 6, 6)
            ..close();
          canvas.drawPath(inner, _fill(_earInner));
          canvas.restore();
        }
        break;
      case DogEar.bat:
        for (final side in const [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(c.dx + side * 38, c.dy - 30);
          canvas.rotate(side * (0.22 + tw + droop));
          final ear = Path()
            ..moveTo(-24, 16)
            ..quadraticBezierTo(-30, -40, 0, -54)
            ..quadraticBezierTo(30, -40, 24, 16)
            ..quadraticBezierTo(0, 24, -24, 16)
            ..close();
          canvas.drawPath(ear, _fill(p));
          final inner = Path()
            ..moveTo(-14, 10)
            ..quadraticBezierTo(-16, -30, 0, -42)
            ..quadraticBezierTo(16, -30, 14, 10)
            ..quadraticBezierTo(0, 16, -14, 10)
            ..close();
          canvas.drawPath(inner, _fill(_earInner));
          canvas.restore();
        }
        break;
      case DogEar.semiErect:
        for (final side in const [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(c.dx + side * 32, c.dy - 30);
          canvas.rotate(side * (0.2 + tw + droop));
          final ear = Path()
            ..moveTo(-16, 14)
            ..quadraticBezierTo(-20, -30, 0, -46)
            ..quadraticBezierTo(20, -30, 16, 14)
            ..close();
          canvas.drawPath(ear, _fill(p));
          final fold = Path()
            ..moveTo(-16, -16)
            ..quadraticBezierTo(0, -28, 16, -16)
            ..quadraticBezierTo(6, 0, 0, 4)
            ..quadraticBezierTo(-8, 0, -16, -16)
            ..close();
          canvas.drawPath(fold, _fill(_darker(p, 0.12)));
          canvas.restore();
        }
        break;
      case DogEar.floppy:
        final long = breed.id == 'beagle';
        final h = long ? 86.0 : 64.0;
        const wdt = 36.0;
        for (final side in const [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(c.dx + side * 44, c.dy - 16);
          canvas.rotate(side * (0.05 + tw + droop));
          final ear = Path()
            ..moveTo(-wdt / 2, -16)
            ..quadraticBezierTo(-wdt / 2 - 10, h * 0.4, -6, h)
            ..quadraticBezierTo(0, h + 6, 6, h)
            ..quadraticBezierTo(wdt / 2 + 10, h * 0.4, wdt / 2, -16)
            ..quadraticBezierTo(0, -28, -wdt / 2, -16)
            ..close();
          final earColor =
              breed.id == 'dachshund' ? _darker(breed.primary, 0.0) : breed.primary;
          canvas.drawPath(ear, _fill(earColor));
          canvas.restore();
        }
        break;
    }
  }

  void _drawMuzzle(Canvas canvas, Offset c, double r) {
    final muzzleColor =
        breed.faceMask ? breed.secondary : _lighter(breed.primary, 0.18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 22), width: 54, height: 40),
      _fill(muzzleColor),
    );
    // Nose.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 10), width: 20, height: 14),
      _fill(const Color(0xFF24201E)),
    );
    canvas.drawCircle(
        Offset(c.dx - 4, c.dy + 6), 3, _fill(Colors.white.withValues(alpha: 0.5)));

    // Mouth + tongue by mood.
    final m = Offset(c.dx, c.dy + 22);
    final line = _stroke(const Color(0xFF3A2A22), 3);
    // Philtrum.
    canvas.drawLine(Offset(m.dx, m.dy - 8), Offset(m.dx, m.dy + 2), line);

    if (mood == DogMood.happy) {
      final smile = Path()
        ..moveTo(m.dx - 20, m.dy + 2)
        ..quadraticBezierTo(m.dx, m.dy + 26, m.dx + 20, m.dy + 2);
      canvas.drawPath(smile, line);
      final open = Path()
        ..moveTo(m.dx - 16, m.dy + 6)
        ..quadraticBezierTo(m.dx, m.dy + 24, m.dx + 16, m.dy + 6)
        ..quadraticBezierTo(m.dx, m.dy + 12, m.dx - 16, m.dy + 6)
        ..close();
      canvas.drawPath(open, _fill(const Color(0xFF6E2B2B)));
      final tongue = Path()
        ..moveTo(m.dx - 9, m.dy + 12)
        ..quadraticBezierTo(m.dx, m.dy + 30, m.dx + 9, m.dy + 12)
        ..quadraticBezierTo(m.dx, m.dy + 18, m.dx - 9, m.dy + 12)
        ..close();
      canvas.drawPath(tongue, _fill(const Color(0xFFF07D8E)));
      canvas.drawLine(Offset(m.dx, m.dy + 14), Offset(m.dx, m.dy + 24),
          _stroke(const Color(0xFFD85F72), 2));
    } else if (mood == DogMood.neutral) {
      final mouth = Path()
        ..moveTo(m.dx - 12, m.dy + 6)
        ..quadraticBezierTo(m.dx, m.dy + 14, m.dx + 12, m.dy + 6);
      canvas.drawPath(mouth, line);
    } else {
      final mouth = Path()
        ..moveTo(m.dx - 12, m.dy + 12)
        ..quadraticBezierTo(m.dx, m.dy + 2, m.dx + 12, m.dy + 12);
      canvas.drawPath(mouth, line);
    }
  }

  void _drawEyes(Canvas canvas, Offset c) {
    final open = 1 - 0.92 * blink;
    for (final side in const [-1.0, 1.0]) {
      final e = Offset(c.dx + side * 22, c.dy - 6);
      if (blink > 0.85) {
        final lid = Path()
          ..moveTo(e.dx - 11, e.dy)
          ..quadraticBezierTo(e.dx, e.dy + 6, e.dx + 11, e.dy);
        canvas.drawPath(lid, _stroke(const Color(0xFF2A211C), 3));
        continue;
      }
      final hh = 14.0 * open;
      canvas.drawOval(
        Rect.fromCenter(center: e, width: 24, height: hh * 2),
        _fill(Colors.white),
      );
      final irisH = math.min(11.0, hh);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(e.dx, e.dy + (mood == DogMood.sad ? 2 : 1)),
            width: 18,
            height: irisH * 1.6),
        _fill(breed.eyeColor),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(e.dx, e.dy + 1),
            width: 9,
            height: math.min(11.0, irisH * 1.4)),
        _fill(const Color(0xFF15110E)),
      );
      canvas.drawCircle(Offset(e.dx - 4, e.dy - 4), 3.2, _fill(Colors.white));
      canvas.drawCircle(
          Offset(e.dx + 3, e.dy + 3), 1.6, _fill(Colors.white.withValues(alpha: 0.7)));
    }

    if (mood == DogMood.sad) {
      for (final side in const [-1.0, 1.0]) {
        final e = Offset(c.dx + side * 22, c.dy - 6);
        final tear = Path()
          ..moveTo(e.dx - 2, e.dy + 10)
          ..quadraticBezierTo(e.dx - 7, e.dy + 20, e.dx, e.dy + 24)
          ..quadraticBezierTo(e.dx + 7, e.dy + 20, e.dx + 2, e.dy + 10)
          ..close();
        canvas.drawPath(tear, _fill(const Color(0xFF7EC8F0).withValues(alpha: 0.85)));
      }
    }
  }

  void _drawBrows(Canvas canvas, Offset c) {
    final bp = _stroke(_darker(breed.primary, 0.25), 3.5);
    for (final side in const [-1.0, 1.0]) {
      final bx = c.dx + side * 22;
      final by = c.dy - 24;
      if (mood == DogMood.sad) {
        // Worried: inner ends raised.
        canvas.drawLine(
            Offset(bx - side * 8, by + 4), Offset(bx + side * 8, by - 3), bp);
      } else if (mood == DogMood.happy) {
        canvas.drawLine(Offset(bx - 8, by - 2), Offset(bx + 8, by - 2), bp);
      } else {
        canvas.drawLine(Offset(bx - 8, by), Offset(bx + 8, by - 1), bp);
      }
    }
  }

  // --------------------------------------------------------- accessories
  void _drawAccessories(Canvas canvas) {
    Accessory? acc(String id) => PetCatalog.accessoryById(id);
    // Neck items first, then glasses, then headwear on top.
    for (final id in equipped) {
      final a = acc(id);
      if (a == null) continue;
      if (a.type == AccessoryType.bandana) _drawBandana(canvas, a.color);
    }
    for (final id in equipped) {
      final a = acc(id);
      if (a == null) continue;
      if (a.type == AccessoryType.bowtie) _drawBowtie(canvas, a.color);
    }
    for (final id in equipped) {
      final a = acc(id);
      if (a == null) continue;
      if (a.type == AccessoryType.glasses) _drawGlasses(canvas, a.color);
    }
    for (final id in equipped) {
      final a = acc(id);
      if (a == null) continue;
      if (a.type == AccessoryType.hat) _drawHat(canvas, a.color);
      if (a.type == AccessoryType.crown) _drawCrown(canvas, a.color);
    }
  }

  void _drawBandana(Canvas canvas, Color color) {
    final path = Path()
      ..moveTo(-34, 2)
      ..lineTo(34, 2)
      ..lineTo(0, 48)
      ..close();
    canvas.drawPath(path, _fill(color));
    canvas.drawCircle(const Offset(0, 4), 7, _fill(_darker(color, 0.12)));
  }

  void _drawBowtie(Canvas canvas, Color color) {
    const c = Offset(0, 8);
    final l = Path()
      ..moveTo(c.dx - 4, c.dy)
      ..lineTo(c.dx - 22, c.dy - 12)
      ..lineTo(c.dx - 22, c.dy + 12)
      ..close();
    final r = Path()
      ..moveTo(c.dx + 4, c.dy)
      ..lineTo(c.dx + 22, c.dy - 12)
      ..lineTo(c.dx + 22, c.dy + 12)
      ..close();
    canvas.drawPath(l, _fill(color));
    canvas.drawPath(r, _fill(color));
    canvas.drawCircle(c, 6, _fill(_darker(color, 0.14)));
  }

  void _drawGlasses(Canvas canvas, Color color) {
    final lens = _stroke(color, 4);
    final tint = _fill(color.withValues(alpha: 0.35));
    for (final side in const [-1.0, 1.0]) {
      final e = Offset(side * 22, -61);
      canvas.drawCircle(e, 14, tint);
      canvas.drawCircle(e, 14, lens);
    }
    canvas.drawLine(const Offset(-8, -61), const Offset(8, -61), lens);
  }

  void _drawHat(Canvas canvas, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -104), width: 86, height: 20),
      _fill(color),
    );
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-26, -150, 52, 50),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, _fill(color));
    canvas.drawRect(
        const Rect.fromLTWH(-26, -116, 52, 8), _fill(const Color(0xFFD9A441)));
  }

  void _drawCrown(Canvas canvas, Color color) {
    const base = -100.0;
    final path = Path()
      ..moveTo(-34, base)
      ..lineTo(-34, base - 18)
      ..lineTo(-18, base - 4)
      ..lineTo(0, base - 26)
      ..lineTo(18, base - 4)
      ..lineTo(34, base - 18)
      ..lineTo(34, base)
      ..close();
    canvas.drawPath(path, _fill(color));
    canvas.drawRect(
        const Rect.fromLTWH(-34, base - 4, 68, 8), _fill(_darker(color, 0.12)));
    canvas.drawCircle(const Offset(0, base - 2), 3, _fill(const Color(0xFFE5484D)));
  }

  @override
  bool shouldRepaint(covariant DogPainter old) => true;
}
