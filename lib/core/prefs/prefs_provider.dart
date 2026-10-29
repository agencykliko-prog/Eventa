import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/tr.dart';
import '../../ui/theme/eventa_colors.dart';
import '../../platform/mobile/prefs_store_mobile.dart'
    if (dart.library.js_interop) '../../platform/web/prefs_store_web.dart';

enum AppLanguage {
  fr('Français', 'fr'),
  en('English', 'en');

  const AppLanguage(this.label, this.code);
  final String label;
  final String code;
}

/// Préférences d'affichage : mode sombre, langue, sons.
@immutable
class AppPrefs {
  const AppPrefs({
    this.dark = false,
    this.language = AppLanguage.fr,
    this.sounds = true,
  });

  final bool dark;
  final AppLanguage language;
  final bool sounds;

  AppPrefs copyWith({bool? dark, AppLanguage? language, bool? sounds}) =>
      AppPrefs(
        dark: dark ?? this.dark,
        language: language ?? this.language,
        sounds: sounds ?? this.sounds,
      );
}

class PrefsNotifier extends Notifier<AppPrefs> {
  @override
  AppPrefs build() {
    final p = AppPrefs(
      dark: readPref('dark') == '1',
      language: readPref('lang') == 'en' ? AppLanguage.en : AppLanguage.fr,
      sounds: readPref('sounds') != '0',
    );
    _apply(p);
    return p;
  }

  void setDark(bool v) => _set(state.copyWith(dark: v));
  void setLanguage(AppLanguage v) => _set(state.copyWith(language: v));
  void setSounds(bool v) => _set(state.copyWith(sounds: v));

  void _set(AppPrefs p) {
    writePref('dark', p.dark ? '1' : '0');
    writePref('lang', p.language.code);
    writePref('sounds', p.sounds ? '1' : '0');
    final repaint = p.dark != state.dark || p.language != state.language;
    _apply(p);
    state = p;
    if (repaint) _rebuildAll();
  }

  static void _apply(AppPrefs p) {
    Confetti.dark = p.dark;
    L10n.lang = p.language.code;
  }

  /// Couleurs et textes sont lus à la construction : on marque tout l'arbre
  /// à reconstruire, sans perdre l'état des écrans (navigation, saisies).
  static void _rebuildAll() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }
}

final prefsProvider = NotifierProvider<PrefsNotifier, AppPrefs>(
  PrefsNotifier.new,
);
