import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../i18n/tr.dart';

/// Les deux mascottes d'Eventa : la rouge accompagne les organisateurs,
/// la verte les créateurs (prestataires et agences).
enum MascotColor {
  organizer('red'),
  creator('green');

  const MascotColor(this._file);
  final String _file;
}

/// Humeur affichée : chaque humeur correspond à une pose illustrée.
enum MascotMood { happy, wow, wink, sleepy, cheer }

/// Poses disponibles pour chaque mascotte.
enum _Shot { jump, thumbs, peace, extra }

String _asset(MascotColor c, _Shot s) {
  final name = switch (s) {
    _Shot.extra => c == MascotColor.organizer ? 'cheeks' : 'wave',
    _ => s.name,
  };
  return 'assets/images/mascots/${c._file}_$name.webp';
}

_Shot _shotFor(MascotMood mood) => switch (mood) {
  MascotMood.happy || MascotMood.wink => _Shot.thumbs,
  MascotMood.cheer => _Shot.jump,
  MascotMood.wow => _Shot.extra,
  MascotMood.sleepy => _Shot.peace,
};

/// Charge les poses à l'avance pour que les changements soient instantanés.
void precacheMascots(BuildContext context) {
  for (final c in MascotColor.values) {
    for (final s in _Shot.values) {
      precacheImage(AssetImage(_asset(c, s)), context);
    }
  }
}

/// Mascotte vivante : respiration, regard, salut, saut au toucher.
/// [look] l'oriente vers un point ; [cover] lui fait fermer les yeux
/// (champ de mot de passe) ; [waving] la fait saluer.
class Mascot extends StatefulWidget {
  const Mascot({
    super.key,
    this.size = 120,
    this.color = MascotColor.organizer,
    this.mood = MascotMood.happy,
    this.look,
    this.cover = false,
    this.waving = false,
    this.arms = true,
    this.legs = true,
    this.idle = true,
    this.onTap,
  });

  /// Côté du widget (carré).
  final double size;
  final MascotColor color;
  final MascotMood mood;
  final Offset? look;
  final bool cover;
  final bool waving;

  /// Conservés pour compatibilité : les illustrations sont toujours entières.
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
  // Seule la transformation change à chaque image : l'image elle-même
  // n'est reconstruite que lorsque la pose change.
  final _frame = ValueNotifier<int>(0);
  Duration _now = Duration.zero;
  Duration? _jumpAt;
  Offset _look = Offset.zero;
  double _wave = 0;
  double _lift = 0, _squash = 0, _sway = 0;
  _Shot? _shot;
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
    _frame.dispose();
    super.dispose();
  }

  /// Petit saut de joie (appelable depuis l'extérieur via une GlobalKey).
  void jump() => _jumpAt = _now;

  void _tick(Duration t) {
    final dt = (t - _now).inMicroseconds / 1e6;
    _now = t;
    final k = (dt * 8).clamp(0.0, 1.0);
    _look = Offset.lerp(_look, widget.look ?? _idleLook(), k)!;
    _wave += ((widget.waving ? 1.0 : 0.0) - _wave) * (dt * 6).clamp(0, 1);

    final s = _now.inMicroseconds / 1e6;
    var lift = 0.0, squash = 0.0;
    if (widget.idle && !_reduced) squash = math.sin(s * 2.6) * 0.25;
    var shot = _shotFor(widget.mood);
    if (widget.cover) shot = _Shot.peace;
    if (_wave > 0.5) {
      shot = widget.color == MascotColor.creator ? _Shot.extra : _Shot.jump;
    }
    final j = _jumpAt;
    if (j != null) {
      final u = (_now - j).inMilliseconds / 620;
      if (u >= 1) {
        _jumpAt = null;
      } else {
        shot = _Shot.jump;
        if (u < 0.15) {
          squash = u / 0.15;
        } else if (u < 0.85) {
          final v = (u - 0.15) / 0.7;
          lift = math.sin(v * math.pi) * 0.18;
          squash = -0.6 * math.sin(v * math.pi);
        } else {
          squash = (1 - (u - 0.85) / 0.15) * 0.9;
        }
      }
    }
    _lift = lift;
    _squash = squash;
    _sway = _wave * math.sin(s * 9) * 0.07 + _look.dx * 0.06;
    if (shot != _shot) {
      setState(() => _shot = shot);
    } else {
      _frame.value++;
    }
  }

  Offset _idleLook() {
    if (!widget.idle || _reduced) return Offset.zero;
    final s = _now.inMilliseconds / 1000;
    return Offset(math.sin(s * 0.7) * 0.4, 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final shot = _shot ?? _shotFor(widget.mood);
    final img = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(a),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: Image.asset(
        _asset(widget.color, shot),
        key: ValueKey(shot),
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
    final body = SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _frame,
        child: img,
        builder: (context, child) => Transform.translate(
          offset: Offset(_look.dx * size * 0.03, -_lift * size),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..rotateZ(_sway)
              ..scaleByDouble(1 + 0.05 * _squash, 1 - 0.05 * _squash, 1, 1),
            child: child,
          ),
        ),
      ),
    );
    final paint = RepaintBoundary(child: body);
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
    this.color = MascotColor.organizer,
  });

  /// Chargement standard, avec des messages de fête qui défilent.
  const MascotLoader.party({super.key, this.color = MascotColor.organizer})
    : size = 96,
      messages = _party;

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
                lift = math.sin(v * math.pi) * 0.2;
                squash = -0.5 * math.sin(v * math.pi);
              } else {
                lift = 0;
                squash = math.sin((u - 0.86) / 0.14 * math.pi) * 0.9;
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Confettis jonglés en arc au-dessus de la tête.
                  for (var i = 0; i < 3; i++) _piece(i, u, w, h),
                  Positioned(
                    left: (w - h) / 2,
                    bottom: lift * h,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..scaleByDouble(
                          1 + 0.06 * squash,
                          1 - 0.06 * squash,
                          1,
                          1,
                        ),
                      child: Image.asset(
                        _asset(
                          widget.color,
                          lift > 0.1 ? _Shot.jump : _Shot.thumbs,
                        ),
                        width: h,
                        height: h,
                        gaplessPlayback: true,
                      ),
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
