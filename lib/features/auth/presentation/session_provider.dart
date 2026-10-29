import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../../../core/analytics/analytics.dart';
import '../../../core/backend/backend.dart';
import '../data/auth_gateway.dart';
import '../domain/profile.dart';

/// Nature de la session : démo (données fictives, aucun compte) ou compte
/// réel sur Supabase.
enum SessionKind { demo, live }

final authGatewayProvider = Provider<AuthGateway>((ref) => const AuthGateway());

/// Session : `null` = déconnecté.
class SessionNotifier extends Notifier<UserProfile?> {
  SessionKind _kind = SessionKind.demo;
  SessionKind get kind => _kind;

  @override
  UserProfile? build() {
    if (!Backend.ready) return null;
    final auth = ref.read(authGatewayProvider);
    // Lien de confirmation ouvert, session expirée ou déconnexion ailleurs.
    final sub = auth.changes.listen((s) {
      if (s.event == AuthChangeEvent.signedOut) {
        if (_kind == SessionKind.live) _clear();
      } else if (s.event == AuthChangeEvent.signedIn && state == null) {
        unawaited(_restore());
      }
    });
    ref.onDispose(sub.cancel);
    // Session conservée par le navigateur : on recharge le profil.
    if (auth.currentUserId != null) unawaited(_restore());
    return null;
  }

  Future<void> _restore() async {
    try {
      final p = await ref.read(authGatewayProvider).loadProfile();
      _set(p, SessionKind.live);
    } catch (e) {
      debugPrint('Session non restaurée : $e');
    }
  }

  void _set(UserProfile p, SessionKind kind) {
    _kind = kind;
    ref.read(sessionKindProvider.notifier).set(kind);
    state = p;
  }

  void _clear() {
    _kind = SessionKind.demo;
    ref.read(sessionKindProvider.notifier).set(SessionKind.demo);
    state = null;
  }

  /// Connexion de démonstration avec le profil fictif du rôle choisi.
  void signIn(UserRole role) {
    _set(
      role == UserRole.creator
          ? UserProfile.demoCreator
          : UserProfile.demoOrganizer,
      SessionKind.demo,
    );
    ref.read(audienceProvider.notifier).track(Metric.signIn);
  }

  /// Inscription de démonstration (aucun compte créé).
  void signUp(UserProfile p) {
    _set(p, SessionKind.demo);
    ref.read(audienceProvider.notifier).track(Metric.signUp);
  }

  /// Connexion à un compte réel. Lève [AuthFailure] avec un message clair.
  Future<void> signInWithPassword(String email, String password) async {
    final p = await ref.read(authGatewayProvider).signIn(email, password);
    _set(p, SessionKind.live);
    ref.read(audienceProvider.notifier).track(Metric.signIn);
  }

  /// Création d'un compte réel. Si la confirmation de l'adresse est
  /// demandée, l'utilisateur reste déconnecté jusqu'au clic sur le lien.
  Future<SignUpOutcome> signUpWithPassword(
    UserProfile p,
    String password,
  ) async {
    final auth = ref.read(authGatewayProvider);
    final outcome = await auth.signUp(p, password);
    ref.read(audienceProvider.notifier).track(Metric.signUp);
    if (outcome == SignUpOutcome.signedIn) {
      _set(await auth.loadProfile(), SessionKind.live);
    }
    return outcome;
  }

  /// Met à jour le profil (enregistré sur le compte réel).
  void update(UserProfile p) {
    state = p;
    if (_kind == SessionKind.live) {
      unawaited(
        ref
            .read(authGatewayProvider)
            .saveProfile(p)
            .catchError((Object e) => debugPrint('Profil non enregistré : $e')),
      );
    }
  }

  void signOut() {
    if (_kind == SessionKind.live && Backend.ready) {
      unawaited(ref.read(authGatewayProvider).signOut());
    }
    _clear();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, UserProfile?>(
  SessionNotifier.new,
);

class _SessionKindNotifier extends Notifier<SessionKind> {
  @override
  SessionKind build() => SessionKind.demo;

  void set(SessionKind k) => state = k;
}

/// Démo ou compte réel : choisit la source des données (fictives ou base).
final sessionKindProvider = NotifierProvider<_SessionKindNotifier, SessionKind>(
  _SessionKindNotifier.new,
);

/// Vrai quand un compte réel est connecté.
final liveSessionProvider = Provider<bool>(
  (ref) =>
      ref.watch(sessionProvider) != null &&
      ref.watch(sessionKindProvider) == SessionKind.live,
);

/// Profil courant (non nul une fois connecté).
final profileProvider = Provider<UserProfile>(
  (ref) => ref.watch(sessionProvider) ?? UserProfile.demoOrganizer,
);
