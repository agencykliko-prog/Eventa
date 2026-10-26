import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../i18n/tr.dart';

/// Couleurs de la mascotte. [orange] est la version principale ; les autres
/// reprennent les teintes secondaires de la marque selon le contexte.
enum MascotColor {
  orange(Color(0xFFFF8A3D), Color(0xFFFFB57E), Color(0xFFDB5F17)),
  coral(Color(0xFFF0585D), Color(0xFFFF9497), Color(0xFFC0353B)),
  violet(Color(0xFF7C63FF), Color(0xFFAC9BFF), Color(0xFF5538D6)),
  lagoon(Color(0xFF16B4A1), Color(0xFF68DCCC), Color(0xFF0A8576)),
  mango(Color(0xFFF2B530), Color(0xFFFFD679), Color(0xFFCB890B)),
  candy(Color(0xFFE863AD), Color(0xFFF7A2D1), Color(0xFFC03C86)),
  gold(Color(0xFFE0B456), Color(0xFFF6DB98), Color(0xFFB4862A));

  const MascotColor(this.base, this.light, this.dark);
  final Color base;
  final Color light;
  final Color dark;
}

enum MascotMood { happy, wow, wink, sleepy, cheer }

/// Pose instantanée de la mascotte, interpolée par les widgets animés.
@immutable
class MascotPose {
  const MascotPose({
    this.mood = MascotMood.happy,
    this.blink = 0,
    this.look = Offset.zero,
    this.wave = 0,
    this.cover = 0,
    this.lift = 0,
    this.squash = 0,
    this.arms = true,
    this.legs = true,
  });

  final MascotMood mood;

  /// 0 = yeux ouverts, 1 = fermés.
  final double blink;

  /// Direction du regard, composantes entre -1 et 1.
  final Offset look;

  /// Angle du bras droit qui salue (0 = repos, 1 = levé).
  final double wave;

  /// Mains devant les yeux (0 à 1) : la mascotte ne regarde pas.
  final double cover;

  /// Hauteur du saut, en unités de dessin.
  final double lift;

  /// Écrasement à l'atterrissage (-1 étiré, 1 écrasé).
  final double squash;

  final bool arms;
  final bool legs;
}

/// Dessin vectoriel de la mascotte Eventa : une goutte de fête à poils
/// courts, grands yeux et sourire franc. Boîte de dessin : 100 × 128.
class MascotPainter extends CustomPainter {
  MascotPainter({required this.color, required this.pose});

  final MascotColor color;
  final MascotPose pose;

  static const box = Size(100, 128);
  static const _pupil = Color(0xFF3A2216);
  static const _mouth = Color(0xFF4A1610);

  /// Corps et fourrure, figés par couleur (enregistrés une fois).
  static final _bodyCache = <MascotColor, ui.Picture>{};

  static Path bodyPath() {
    const cx = 50.0, cy = 66.0, r = 33.0;
    return Path()
      ..moveTo(55, 6)
      ..cubicTo(60, 22, 83, 38, cx + r, cy)
      ..arcTo(
        Rect.fromCircle(center: const Offset(cx, cy), radius: r),
        0,
        math.pi,
        false,
      )
      ..cubicTo(17, 40, 38, 30, 47, 14)
      ..cubicTo(49, 10, 51, 7, 55, 6)
      ..close();
  }

  ui.Picture _body() => _bodyCache.putIfAbsent(color, () {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final body = bodyPath();
    final rnd = math.Random(11);

    // Silhouette duveteuse : mèches courtes vers l'extérieur.
    final edge = Paint()
      ..color = color.base
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.1;
    for (final m in body.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 1.25) {
        final t = m.getTangentForOffset(d)!;
        final n = Offset(t.vector.dy, -t.vector.dx);
        final len = 1.6 + rnd.nextDouble() * 2.2;
        final tilt = (rnd.nextDouble() - 0.5) * 0.9;
        final dir = Offset(
          n.dx * math.cos(tilt) - n.dy * math.sin(tilt),
          n.dx * math.sin(tilt) + n.dy * math.cos(tilt),
        );
        edge.color = Color.lerp(
          color.base,
          t.position.dy > 66 ? color.dark : color.light,
          rnd.nextDouble() * 0.45,
        )!;
        c.drawLine(
          t.position - n * 0.8,
          t.position + dir * len,
          edge,
        );
      }
    }

    // Volume : lumière en haut à gauche, ombre douce en bas à droite.
    c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(36, 48),
          62,
          [color.light, color.base, color.dark],
          const [0, 0.5, 1],
        ),
    );

    // Texture de fourrure : touches courtes claires et sombres.
    c.save();
    c.clipPath(body);
    final fur = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9;
    for (var i = 0; i < 900; i++) {
      final p = Offset(10 + rnd.nextDouble() * 80, 4 + rnd.nextDouble() * 96);
      if (!body.contains(p)) continue;
      final a = math.atan2(p.dy - 70, p.dx - 50) + (rnd.nextDouble() - 0.5);
      final len = 1.2 + rnd.nextDouble() * 1.8;
      final lightSide = p.dx + p.dy < 110;
      fur.color = (rnd.nextBool() == lightSide ? color.light : color.dark)
          .withValues(alpha: 0.18 + rnd.nextDouble() * 0.22);
      c.drawLine(
        p,
        p + Offset(math.cos(a), math.sin(a)) * len,
        fur,
      );
    }
    // Reflet doux.
    c.drawOval(
      const Rect.fromLTWH(26, 34, 18, 11),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    c.restore();
    return rec.endRecording();
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / box.width, size.height / box.height);
    canvas.save();
    canvas.translate(
      (size.width - box.width * s) / 2,
      (size.height - box.height * s) / 2,
    );
    canvas.scale(s);

    final p = pose;
    final sq = p.squash.clamp(-1.0, 1.0);

    if (p.legs) _legs(canvas, p);

    // Corps : saut + écrasement autour du point d'appui.
    canvas.save();
    canvas.translate(0, -p.lift);
    canvas.translate(50, 99);
    canvas.scale(1 + sq * 0.07, 1 - sq * 0.08);
    canvas.translate(-50, -99);
    canvas.drawPicture(_body());
    _face(canvas, p);
    if (p.arms) _arms(canvas, p);
    canvas.restore();
    canvas.restore();
  }

  void _legs(Canvas canvas, MascotPose p) {
    final leg = Paint()
      ..color = color.dark
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.2;
    final top = 96 - p.lift;
    for (final x in [41.0, 59.0]) {
      final foot = Offset(x + (x < 50 ? -2 : 2), 121);
      canvas.drawLine(Offset(x, top), foot - const Offset(0, 2), leg);
      canvas.drawOval(
        Rect.fromCenter(
          center: foot + Offset(x < 50 ? -2.5 : 2.5, 0.5),
          width: 12,
          height: 6,
        ),
        Paint()..color = color.dark,
      );
    }
    // Ombre portée, plus petite pendant le saut.
    final k = (1 - p.lift / 40).clamp(0.4, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 125),
        width: 46 * k,
        height: 5 * k,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10 * k)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _arms(Canvas canvas, MascotPose p) {
    final arm = Paint()
      ..color = color.dark
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.6;
    final hand = Paint()..color = color.light;
    final handEdge = Paint()
      ..color = color.dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    void limb(Offset shoulder, Offset handAt, double bend) {
      final mid = Offset.lerp(shoulder, handAt, 0.5)! + Offset(0, bend);
      canvas.drawPath(
        Path()
          ..moveTo(shoulder.dx, shoulder.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, handAt.dx, handAt.dy),
        arm,
      );
      canvas.drawCircle(handAt, 6.4, hand);
      canvas.drawCircle(handAt, 6.4, handEdge);
    }

    final c = p.cover;
    // Bras gauche : repos sur la hanche, ou devant l'œil gauche.
    final restL = const Offset(9, 88);
    final eyeL = const Offset(38, 58);
    limb(const Offset(20, 74), Offset.lerp(restL, eyeL, c)!, 6 - c * 10);

    // Bras droit : salue (angle oscillant), ou devant l'œil droit.
    final angle = -0.35 - p.wave * 1.9;
    final wave = const Offset(83, 74) + Offset(math.cos(angle), math.sin(angle)) * 20;
    final restR = const Offset(91, 88);
    final rightRest = Offset.lerp(restR, wave, p.wave.clamp(0, 1))!;
    limb(
      const Offset(80, 74),
      Offset.lerp(rightRest, const Offset(62, 58), c)!,
      6 - c * 10 - p.wave * 8,
    );
  }

  void _face(Canvas canvas, MascotPose p) {
    final look = p.look * (1 - p.cover);
    final shy = p.cover > 0.5;
    final blink = shy ? 1.0 : p.blink;
    final eyeY = 56.0 + look.dy * 1.5;
    final dark = Paint()
      ..color = _mouth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    // Sourcils : expressifs selon l'humeur.
    final browLift = switch (p.mood) {
      MascotMood.wow || MascotMood.cheer => 4.0,
      MascotMood.sleepy => -1.0,
      _ => 0.0,
    };
    final brow = Paint()
      ..color = color.dark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    for (final x in [38.0, 62.0]) {
      final y = eyeY - 16 - browLift;
      canvas.drawPath(
        Path()
          ..moveTo(x - 6, y + 1.5)
          ..quadraticBezierTo(x, y - 2, x + 6, y + 1.5),
        brow,
      );
    }

    // Yeux.
    for (final (i, x) in [38.0, 62.0].indexed) {
      final closed = p.mood == MascotMood.sleepy ||
          (p.mood == MascotMood.wink && i == 1);
      final h = closed ? 0.0 : 12.0 * (1 - blink);
      if (h < 1.5) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 6.5, eyeY)
            ..quadraticBezierTo(x, eyeY + (closed ? 4 : 2.5), x + 6.5, eyeY),
          dark,
        );
        continue;
      }
      final eye = Rect.fromCenter(
        center: Offset(x, eyeY),
        width: 18,
        height: h * 2,
      );
      canvas.drawOval(
        eye.shift(const Offset(0, 1)),
        Paint()..color = color.dark.withValues(alpha: 0.35),
      );
      canvas.drawOval(eye, Paint()..color = Colors.white);
      canvas.save();
      canvas.clipPath(Path()..addOval(eye));
      final pc = Offset(x + look.dx * 3.6, eyeY + 1 + look.dy * 3.6);
      final pr = p.mood == MascotMood.wow ? 5.0 : 6.2;
      canvas.drawCircle(pc, pr, Paint()..color = _pupil);
      canvas.drawCircle(
        pc + const Offset(-2, -2.4),
        1.9,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        pc + const Offset(2.2, 1.8),
        0.9,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
      canvas.restore();
    }

    // Joues.
    final cheek = Paint()
      ..color = const Color(0xFFFF5E7E).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(27, eyeY + 15), width: 11, height: 6),
      cheek,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(73, eyeY + 15), width: 11, height: 6),
      cheek,
    );

    // Bouche.
    final my = eyeY + 18;
    switch (p.mood) {
      case MascotMood.wow:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(50, my + 3), width: 10, height: 12),
          Paint()..color = _mouth,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(50, my + 6), width: 6, height: 4),
          Paint()..color = const Color(0xFFE8606F),
        );
      case MascotMood.sleepy:
        canvas.drawPath(
          Path()
            ..moveTo(45, my + 2)
            ..quadraticBezierTo(50, my + 5, 55, my + 2),
          dark,
        );
      case MascotMood.happy || MascotMood.wink || MascotMood.cheer:
        final w = p.mood == MascotMood.cheer ? 15.0 : 12.5;
        final d = p.mood == MascotMood.cheer ? 15.0 : 11.0;
        final mouth = Path()
          ..moveTo(50 - w, my)
          ..quadraticBezierTo(50, my - 2, 50 + w, my)
          ..quadraticBezierTo(50 + w * 0.7, my + d, 50, my + d)
          ..quadraticBezierTo(50 - w * 0.7, my + d, 50 - w, my)
          ..close();
        canvas.drawPath(mouth, Paint()..color = _mouth);
        canvas.save();
        canvas.clipPath(mouth);
        // Dents du haut.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(50 - w * 0.75, my - 3, w * 1.5, 5.2),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white,
        );
        // Langue.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(50, my + d - 1),
            width: w * 1.1,
            height: d * 0.7,
          ),
          Paint()..color = const Color(0xFFE8606F),
        );
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MascotPainter old) =>
      old.color != color || old.pose != pose;
}

/// Mascotte vivante : respiration, clignements, regard, salut, saut au
/// toucher. [look] oriente le regard ; [cover] lui fait cacher ses yeux.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.size = 120,
    this.color = MascotColor.orange,
    this.mood = MascotMood.happy,
    this.look,
    this.cover = false,
    this.waving = false,
    this.arms = true,
    this.legs = true,
    this.idle = true,
    this.onTap,
  });

  /// Hauteur du widget (la largeur suit le ratio 100 : 128).
  final double size;
  final MascotColor color;
  final MascotMood mood;
  final Offset? look;
  final bool cover;
  final bool waving;
  final bool arms;
  final bool legs;
  final bool idle;

  /// Appelé après le petit saut déclenché par un toucher.
  final VoidCallback? onTap;

  @override
  State<Mascot> createState() => MascotState();
}

class MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rnd = math.Random();
  Duration _now = Duration.zero;
  Duration? _jumpAt;
  Duration _nextBlink = const Duration(milliseconds: 1800);
  Offset _look = Offset.zero;
  double _cover = 0;
  double _wave = 0;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Petit saut de joie (appelable depuis l'extérieur via une GlobalKey).
  void jump() => setState(() => _jumpAt = _now);

  void _tick(Duration t) {
    final dt = (t - _now).inMicroseconds / 1e6;
    _now = t;
    final k = (dt * 9).clamp(0.0, 1.0);
    _look = Offset.lerp(_look, widget.look ?? _idleLook(), k)!;
    _cover += ((widget.cover ? 1.0 : 0.0) - _cover) * (dt * 10).clamp(0, 1);
    _wave += ((widget.waving ? 1.0 : 0.0) - _wave) * (dt * 6).clamp(0, 1);
    if (t > _nextBlink + const Duration(milliseconds: 170)) {
      _nextBlink = t + Duration(milliseconds: 2200 + _rnd.nextInt(2600));
    }
    setState(() {});
  }

  Offset _idleLook() {
    if (!widget.idle || _reduced) return Offset.zero;
    final s = _now.inMilliseconds / 1000;
    return Offset(math.sin(s * 0.7) * 0.5, math.sin(s * 0.45) * 0.25);
  }

  MascotPose get _pose {
    final s = _now.inMicroseconds / 1e6;
    var lift = 0.0, squash = 0.0;
    if (widget.idle && !_reduced) {
      squash = math.sin(s * 2.6) * 0.25;
    }
    final j = _jumpAt;
    var mood = widget.mood;
    if (j != null) {
      final u = (_now - j).inMilliseconds / 620;
      if (u >= 1) {
        _jumpAt = null;
      } else {
        mood = MascotMood.cheer;
        if (u < 0.15) {
          squash = u / 0.15; // prise d'élan
        } else if (u < 0.85) {
          final v = (u - 0.15) / 0.7;
          lift = math.sin(v * math.pi) * 22;
          squash = -0.6 * math.sin(v * math.pi);
        } else {
          squash = (1 - (u - 0.85) / 0.15) * 0.9; // atterrissage
        }
      }
    }
    final blinkPhase = (_now - _nextBlink).inMilliseconds;
    final blink = blinkPhase >= 0 && blinkPhase < 170
        ? math.sin(blinkPhase / 170 * math.pi)
        : 0.0;
    final wave = _wave * (0.65 + 0.35 * math.sin(s * 11));
    return MascotPose(
      mood: mood,
      blink: blink,
      look: _look,
      wave: wave,
      cover: _cover,
      lift: lift,
      squash: squash,
      arms: widget.arms,
      legs: widget.legs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size * MascotPainter.box.width / MascotPainter.box.height;
    final paint = RepaintBoundary(
      child: CustomPaint(
        size: Size(w, widget.size),
        painter: MascotPainter(color: widget.color, pose: _pose),
      ),
    );
    if (widget.onTap == null) return ExcludeSemantics(child: paint);
    return Semantics(
      button: true,
      label: 'Mascotte Eventa'.tr,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            jump();
            widget.onTap?.call();
          },
          child: paint,
        ),
      ),
    );
  }
}

/// Mascotte qui sautille en jonglant avec des confettis, pendant les temps
/// d'attente. Les messages défilent sous elle.
class MascotLoader extends StatefulWidget {
  const MascotLoader({
    super.key,
    this.size = 96,
    this.messages = const [],
    this.color = MascotColor.orange,
  });

  /// Chargement standard, avec des messages de fête qui défilent.
  const MascotLoader.party({super.key})
    : size = 96,
      messages = _party,
      color = MascotColor.orange;

  static const _party = [
    'On prépare la fête…',
    'On gonfle les ballons…',
    'On compte les FCFA…',
    'On range les confettis…',
  ];

  final double size;
  final List<String> messages;
  final MascotColor color;

  @override
  State<MascotLoader> createState() => _MascotLoaderState();
}

class _MascotLoaderState extends State<MascotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  int _msg = 0;

  static const _confetti = [
    Color(0xFFF0585D),
    Color(0xFF7C63FF),
    Color(0xFF16B4A1),
    Color(0xFFF2B530),
    Color(0xFFE863AD),
  ];

  @override
  void initState() {
    super.initState();
    _c.addListener(_cycle);
  }

  double _last = 0;
  int _beats = 0;

  void _cycle() {
    if (_c.value < _last) {
      _beats++;
      if (_beats % 2 == 0 && widget.messages.length > 1) {
        setState(() => _msg = (_msg + 1) % widget.messages.length);
      }
    }
    _last = _c.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.size;
    final w = h * 1.4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: w,
          height: h * 1.55,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final u = _c.value;
              // Saut : prise d'élan, vol, atterrissage.
              double lift, squash;
              if (u < 0.18) {
                lift = 0;
                squash = math.sin(u / 0.18 * math.pi) * 0.8;
              } else if (u < 0.86) {
                final v = (u - 0.18) / 0.68;
                lift = math.sin(v * math.pi) * 18;
                squash = -0.5 * math.sin(v * math.pi);
              } else {
                lift = 0;
                squash = math.sin((u - 0.86) / 0.14 * math.pi) * 0.9;
              }
              final pose = MascotPose(
                mood: lift > 10 ? MascotMood.cheer : MascotMood.happy,
                look: const Offset(0, -0.9),
                wave: lift / 18,
                lift: lift,
                squash: squash,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Confettis jonglés en arc au-dessus de la tête.
                  for (var i = 0; i < 3; i++)
                    _piece(i, u, w, h),
                  Positioned(
                    left: (w - h * 100 / 128) / 2,
                    bottom: 0,
                    child: CustomPaint(
                      size: Size(h * 100 / 128, h),
                      painter: MascotPainter(color: widget.color, pose: pose),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.messages.isNotEmpty) ...[
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Text(
              widget.messages[_msg % widget.messages.length].tr,
              key: ValueKey(_msg),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _piece(int i, double u, double w, double h) {
    // Chaque confetti suit une parabole décalée d'un tiers de cycle.
    final p = (u + i / 3) % 1;
    final x = w / 2 + math.cos(p * math.pi) * w * 0.34;
    final y = h * 0.42 - math.sin(p * math.pi) * h * 0.38;
    return Positioned(
      left: x - 5,
      top: y,
      child: Transform.rotate(
        angle: p * math.pi * 3 + i,
        child: Container(
          width: 10,
          height: i == 1 ? 10 : 6,
          decoration: BoxDecoration(
            color: _confetti[i % _confetti.length],
            borderRadius: BorderRadius.circular(i == 1 ? 5 : 2),
          ),
        ),
      ),
    );
  }
}
