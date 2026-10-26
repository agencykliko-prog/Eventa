import 'en.dart';

/// Langue de l'interface. Le français est la langue source : chaque texte
/// sert de clé, et sa traduction anglaise est cherchée dans [en].
abstract final class L10n {
  static String lang = 'fr';

  static bool get isEn => lang == 'en';

  /// Locale `intl` pour les dates et les nombres.
  static String get intl => isEn ? 'en_US' : 'fr_FR';
}

extension Tr on String {
  /// Texte traduit (ou inchangé en français / sans traduction connue).
  String get tr => L10n.isEn ? (en[this] ?? this) : this;

  /// Texte à trous : `'Bonjour {0}'.trf([nom])`.
  String trf(List<Object?> args) {
    var s = tr;
    for (var i = 0; i < args.length; i++) {
      s = s.replaceAll('{$i}', '${args[i]}');
    }
    return s;
  }
}
