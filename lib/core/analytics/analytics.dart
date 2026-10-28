import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mesure d'audience anonyme, gardée sur l'appareil en démo. Les écrans sont
// enregistrés par modèle de chemin (« /prestataire/:id ») : jamais
// d'identifiant, de nom ni de texte saisi.

/// Événements clés du parcours.
enum Metric {
  pageView('Écran vu'),
  signIn('Connexion'),
  signUp('Inscription'),
  quoteRequest('Demande de devis'),
  booking('Réservation'),
  payment('Paiement'),
  messageSent('Message envoyé'),
  quoteSent('Devis envoyé (Creator)'),
  verificationSubmitted('Dossier de vérification envoyé');

  const Metric(this.label);

  /// Libellé du centre de contrôle (français uniquement).
  final String label;
}

@immutable
class Hit {
  const Hit(this.metric, this.at, {this.screen});
  final Metric metric;
  final DateTime at;

  /// Modèle de chemin, pour les écrans vus.
  final String? screen;
}

/// Plafond du journal local, pour ne pas grossir indéfiniment.
const _maxHits = 500;

class AudienceNotifier extends Notifier<List<Hit>> {
  @override
  List<Hit> build() => const [];

  /// Mesure désactivée par l'utilisateur dans son compte.
  bool get _off => !ref.read(audienceConsentProvider);

  void track(Metric m) {
    if (_off) return;
    _add(Hit(m, DateTime.now()));
  }

  /// Écran affiché. Les doublons consécutifs (même écran) sont ignorés.
  void screen(String template) {
    if (_off || template.isEmpty) return;
    final last = state.lastOrNull;
    if (last?.metric == Metric.pageView && last?.screen == template) return;
    _add(Hit(Metric.pageView, DateTime.now(), screen: template));
  }

  void _add(Hit h) {
    final next = [...state, h];
    state = next.length > _maxHits
        ? next.sublist(next.length - _maxHits)
        : next;
  }

  void clear() => state = const [];
}

final audienceProvider = NotifierProvider<AudienceNotifier, List<Hit>>(
  AudienceNotifier.new,
);

/// Consentement à la mesure d'audience (activée par défaut, anonyme).
class AudienceConsent extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool on) {
    state = on;
    if (!on) ref.read(audienceProvider.notifier).clear();
  }
}

final audienceConsentProvider = NotifierProvider<AudienceConsent, bool>(
  AudienceConsent.new,
);

/// Synthèse pour le centre de contrôle.
@immutable
class AudienceSummary {
  const AudienceSummary({
    required this.pageViews,
    required this.topScreens,
    required this.events,
  });

  final int pageViews;

  /// Écrans les plus vus, du plus au moins consulté.
  final List<(String, int)> topScreens;

  /// Nombre d'occurrences de chaque événement clé (hors écrans vus).
  final Map<Metric, int> events;
}

final audienceSummaryProvider = Provider<AudienceSummary>((ref) {
  final hits = ref.watch(audienceProvider);
  final screens = <String, int>{};
  final events = <Metric, int>{};
  for (final h in hits) {
    if (h.metric == Metric.pageView) {
      screens.update(h.screen!, (n) => n + 1, ifAbsent: () => 1);
    } else {
      events.update(h.metric, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  final top = [for (final e in screens.entries) (e.key, e.value)]
    ..sort((a, b) => b.$2.compareTo(a.$2));
  return AudienceSummary(
    pageViews: hits.where((h) => h.metric == Metric.pageView).length,
    topScreens: top.take(6).toList(),
    events: events,
  );
});
