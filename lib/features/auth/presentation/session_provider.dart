import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../domain/profile.dart';

/// Session simulée : `null` = déconnecté. Aucun backend en démo.
class SessionNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => null;

  /// Connexion de démonstration avec le profil fictif du rôle choisi.
  void signIn(UserRole role) {
    state = role == UserRole.creator
        ? UserProfile.demoCreator
        : UserProfile.demoOrganizer;
    ref.read(audienceProvider.notifier).track(Metric.signIn);
  }

  void signUp(UserProfile p) {
    state = p;
    ref.read(audienceProvider.notifier).track(Metric.signUp);
  }

  void update(UserProfile p) => state = p;

  void signOut() => state = null;
}

final sessionProvider = NotifierProvider<SessionNotifier, UserProfile?>(
  SessionNotifier.new,
);

/// Profil courant (non nul une fois connecté).
final profileProvider = Provider<UserProfile>(
  (ref) => ref.watch(sessionProvider) ?? UserProfile.demoOrganizer,
);
