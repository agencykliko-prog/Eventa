import 'package:flutter/material.dart';

/// Palette Confetti, version premium : teintes approfondies d'un cran,
/// encre nuit plus dense, fond blanc cassé légèrement grisé.
abstract final class Confetti {
  static const coral = Color(0xFFE5484D); // primaire, CTA
  static const coralDeep = Color(0xFFA3262B);
  static const coralTint = Color(0xFFFCE9E8);

  static const violet = Color(0xFF6246EA); // tâches
  static const violetText = Color(0xFF4B30C9);
  static const violetDeep = Color(0xFF2A1A80);
  static const violetTint = Color(0xFFECE8FD);

  static const lagoon = Color(0xFF0E9F8E); // budget
  static const lagoonText = Color(0xFF0A6E63);
  static const lagoonDeep = Color(0xFF054239);
  static const lagoonTint = Color(0xFFDDF4F0);

  static const mango = Color(0xFFE5A21A); // prestataires
  static const mangoText = Color(0xFF7A4E00);
  static const mangoDeep = Color(0xFF4E3200);
  static const mangoTint = Color(0xFFFBEFD3);

  static const candy = Color(0xFFDB4F9E); // équipes
  static const candyText = Color(0xFFA11F6C);
  static const candyDeep = Color(0xFF650E43);
  static const candyTint = Color(0xFFFBE3F0);

  static const ink = Color(0xFF1A0637); // texte et icônes (violet nuit)
  static const night = Color(0xFF221043);
  static const nightLine = Color(0xFF362458);
  static const inkMuted = Color(0xFF645A7C);
  static const inkFaint = Color(0xFF9A95AE);
  static const cream = Color(0xFFF7F5F2); // fond
  static const lavender = Color(0xFFEAE7F3); // surfaces
  static const line = Color(0xFFE4E0EC);

  /// Or discret réservé aux marqueurs Premium.
  static const gold = Color(0xFFD9A93F);
  static const goldTint = Color(0xFFF7EBCB);

  static const success = Color(0xFF17804A);
  static const warning = Color(0xFFA86200);
  static const danger = Color(0xFFC92A2A);
}

/// Un rôle de couleur complet : fond teinté, couleur vive, texte lisible.
@immutable
class Hue {
  const Hue({
    required this.base,
    required this.text,
    required this.deep,
    required this.tint,
  });

  final Color base;
  final Color text;
  final Color deep;
  final Color tint;

  /// Couleur de premier plan lisible posée sur [base].
  Color get onBase => base == Confetti.mango ? deep : Colors.white;

  static const coral = Hue(
    base: Confetti.coral,
    text: Confetti.coralDeep,
    deep: Color(0xFF6E1418),
    tint: Confetti.coralTint,
  );
  static const violet = Hue(
    base: Confetti.violet,
    text: Confetti.violetText,
    deep: Confetti.violetDeep,
    tint: Confetti.violetTint,
  );
  static const lagoon = Hue(
    base: Confetti.lagoon,
    text: Confetti.lagoonText,
    deep: Confetti.lagoonDeep,
    tint: Confetti.lagoonTint,
  );
  static const mango = Hue(
    base: Confetti.mango,
    text: Confetti.mangoText,
    deep: Confetti.mangoDeep,
    tint: Confetti.mangoTint,
  );
  static const candy = Hue(
    base: Confetti.candy,
    text: Confetti.candyText,
    deep: Confetti.candyDeep,
    tint: Confetti.candyTint,
  );
  static const ink = Hue(
    base: Confetti.ink,
    text: Confetti.ink,
    deep: Color(0xFF0A0918),
    tint: Confetti.lavender,
  );
  static const gold = Hue(
    base: Confetti.gold,
    text: Color(0xFF7A5A12),
    deep: Color(0xFF4A360A),
    tint: Confetti.goldTint,
  );
}

/// Couleurs des modules, exposées via le thème.
@immutable
class EventaColors extends ThemeExtension<EventaColors> {
  const EventaColors({
    required this.budget,
    required this.tasks,
    required this.vendors,
    required this.team,
    required this.brand,
    required this.muted,
    required this.line,
    required this.surface,
  });

  final Hue budget;
  final Hue tasks;
  final Hue vendors;
  final Hue team;
  final Hue brand;
  final Color muted;
  final Color line;
  final Color surface;

  static const light = EventaColors(
    budget: Hue.lagoon,
    tasks: Hue.violet,
    vendors: Hue.mango,
    team: Hue.candy,
    brand: Hue.coral,
    muted: Confetti.inkMuted,
    line: Confetti.line,
    surface: Colors.white,
  );

  @override
  EventaColors copyWith() => this;

  @override
  EventaColors lerp(EventaColors? other, double t) => other ?? this;
}

extension EventaThemeX on BuildContext {
  EventaColors get eventa => Theme.of(this).extension<EventaColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
