import 'package:flutter/material.dart';

/// Palette Confetti, version premium : teintes approfondies d'un cran,
/// encre nuit plus dense, fond blanc cassé légèrement grisé.
///
/// Chaque couleur a sa variante sombre : [dark] est piloté par les
/// préférences (voir `prefs_provider.dart`), qui reconstruisent l'arbre
/// entier quand il change.
abstract final class Confetti {
  static bool dark = false;

  static Color _c(int light, int night) => Color(dark ? night : light);

  static Color get coral => _c(0xFFE5484D, 0xFFF0585D); // primaire, CTA
  static Color get coralDeep => _c(0xFFA3262B, 0xFFFF9A9D);
  static Color get coralTint => _c(0xFFFCE9E8, 0xFF3B1526);

  static Color get violet => _c(0xFF6246EA, 0xFF7C63FF); // tâches
  static Color get violetText => _c(0xFF4B30C9, 0xFFB3A3FF);
  static Color get violetDeep => _c(0xFF2A1A80, 0xFFD4CBFF);
  static Color get violetTint => _c(0xFFECE8FD, 0xFF261A55);

  static Color get lagoon => _c(0xFF0E9F8E, 0xFF16B4A1); // budget
  static Color get lagoonText => _c(0xFF0A6E63, 0xFF5FD9C8);
  static Color get lagoonDeep => _c(0xFF054239, 0xFFB5F0E7);
  static Color get lagoonTint => _c(0xFFDDF4F0, 0xFF0D302F);

  static Color get mango => _c(0xFFE5A21A, 0xFFEBAE2E); // prestataires
  static Color get mangoText => _c(0xFF7A4E00, 0xFFF4C766);
  static Color get mangoDeep => _c(0xFF4E3200, 0xFFFBE2A8);
  static Color get mangoTint => _c(0xFFFBEFD3, 0xFF33270C);

  static Color get candy => _c(0xFFDB4F9E, 0xFFE863AD); // équipes
  static Color get candyText => _c(0xFFA11F6C, 0xFFF59BCD);
  static Color get candyDeep => _c(0xFF650E43, 0xFFFBD0E8);
  static Color get candyTint => _c(0xFFFBE3F0, 0xFF3A1332);

  /// Texte et icônes (violet nuit en clair, lavande pâle en sombre).
  static Color get ink => _c(0xFF1A0637, 0xFFF1EDFA);

  /// Premier plan posé sur [ink] (pastilles et boutons « encre »).
  static Color get onInk => _c(0xFFFFFFFF, 0xFF140829);
  static Color get night => _c(0xFF221043, 0xFF26174A);
  static Color get nightLine => _c(0xFF362458, 0xFF3D2C66);
  static Color get inkMuted => _c(0xFF645A7C, 0xFFB1A8C8);
  static Color get inkFaint => _c(0xFF9A95AE, 0xFF7C7496);
  static Color get cream => _c(0xFFF7F5F2, 0xFF110722); // fond
  static Color get surface => _c(0xFFFFFFFF, 0xFF1B0F33); // cartes
  static Color get lavender => _c(0xFFEAE7F3, 0xFF271A45); // surfaces
  static Color get line => _c(0xFFE4E0EC, 0xFF2F2250);

  /// Contours de contrôles (cases, pastilles vides).
  static Color get border => _c(0xFFCBC5DA, 0xFF4A3B6E);

  /// Or discret réservé aux marqueurs Premium.
  static Color get gold => _c(0xFFD9A93F, 0xFFE0B456);
  static Color get goldTint => _c(0xFFF7EBCB, 0xFF33290F);

  static Color get success => _c(0xFF17804A, 0xFF3DC27C);
  static Color get warning => _c(0xFFA86200, 0xFFF0A23C);
  static Color get danger => _c(0xFFC92A2A, 0xFFFF6B6B);

  /// Encre fixe, quel que soit le mode (texte sur fond blanc ou mangue).
  static const inkFixed = Color(0xFF1A0637);
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
  Color get onBase =>
      base == Confetti.mango ? const Color(0xFF4E3200) : Colors.white;

  @override
  bool operator ==(Object other) => other is Hue && other.base == base;

  @override
  int get hashCode => base.hashCode;

  static Hue get coral => Hue(
    base: Confetti.coral,
    text: Confetti.coralDeep,
    deep: Confetti.dark ? const Color(0xFFFFC9CB) : const Color(0xFF6E1418),
    tint: Confetti.coralTint,
  );
  static Hue get violet => Hue(
    base: Confetti.violet,
    text: Confetti.violetText,
    deep: Confetti.violetDeep,
    tint: Confetti.violetTint,
  );
  static Hue get lagoon => Hue(
    base: Confetti.lagoon,
    text: Confetti.lagoonText,
    deep: Confetti.lagoonDeep,
    tint: Confetti.lagoonTint,
  );
  static Hue get mango => Hue(
    base: Confetti.mango,
    text: Confetti.mangoText,
    deep: Confetti.mangoDeep,
    tint: Confetti.mangoTint,
  );
  static Hue get candy => Hue(
    base: Confetti.candy,
    text: Confetti.candyText,
    deep: Confetti.candyDeep,
    tint: Confetti.candyTint,
  );
  static Hue get ink => Hue(
    base: Confetti.ink,
    text: Confetti.ink,
    deep: Confetti.dark ? Colors.white : const Color(0xFF0A0918),
    tint: Confetti.lavender,
  );
  static Hue get gold => Hue(
    base: Confetti.gold,
    text: Confetti.dark ? const Color(0xFFF0CC7A) : const Color(0xFF7A5A12),
    deep: Confetti.dark ? const Color(0xFFF7E3B0) : const Color(0xFF4A360A),
    tint: Confetti.goldTint,
  );
}

/// Référence constante à une teinte, pour les enums et les valeurs `const`.
enum Hues {
  coral,
  violet,
  lagoon,
  mango,
  candy,
  ink,
  gold;

  Hue get hue => switch (this) {
    Hues.coral => Hue.coral,
    Hues.violet => Hue.violet,
    Hues.lagoon => Hue.lagoon,
    Hues.mango => Hue.mango,
    Hues.candy => Hue.candy,
    Hues.ink => Hue.ink,
    Hues.gold => Hue.gold,
  };
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

  /// Jeu de couleurs du mode courant ([Confetti.dark]).
  static EventaColors get current => EventaColors(
    budget: Hue.lagoon,
    tasks: Hue.violet,
    vendors: Hue.mango,
    team: Hue.candy,
    brand: Hue.coral,
    muted: Confetti.inkMuted,
    line: Confetti.line,
    surface: Confetti.surface,
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
