import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/i18n/tr.dart';
import '../../admin/domain/admin_models.dart';
import '../../admin/presentation/admin_providers.dart';
import '../../auth/presentation/session_provider.dart';

// ─── Vérification du prestataire ────────────────────────────────────────
// Le Creator dépose ses pièces et envoie son dossier ; l'équipe Eventa le
// contrôle dans le centre de contrôle (module Vérification). Sa décision
// revient ici et pilote le badge « Vérifié » de la fiche.

enum ProofKind {
  identity('Pièce d’identité du gérant', 'CNI, passeport ou carte consulaire'),
  rccm('Registre du commerce (RCCM)', 'Ou attestation d’auto-entrepreneur'),
  address('Justificatif d’adresse', 'Facture CIE, SODECI ou bail'),
  portfolio('Photos de réalisations', 'Au moins 3 prestations récentes'),
  payout(
    'Compte de reversement',
    'Numéro Mobile Money ou RIB au nom de l’entreprise',
  );

  const ProofKind(this._label, this._hint);
  final String _label;
  final String _hint;
  String get label => _label.tr;
  String get hint => _hint.tr;
}

enum VerificationStep {
  draft('À compléter'),
  pending('En cours de vérification'),
  info('Informations demandées'),
  verified('Vérifié'),
  rejected('Refusé');

  const VerificationStep(this._label);
  final String _label;
  String get label => _label.tr;
}

@immutable
class Verification {
  const Verification({
    this.provided = const {},
    this.step = VerificationStep.draft,
    this.checkId,
    this.submittedAt,
    this.comment,
  });

  final Set<ProofKind> provided;
  final VerificationStep step;

  /// Dossier correspondant dans le centre de contrôle.
  final String? checkId;
  final DateTime? submittedAt;

  /// Motif ou précision laissés par l'équipe.
  final String? comment;

  bool get complete => provided.length == ProofKind.values.length;

  /// Le dossier peut être (ré)envoyé.
  bool get canSubmit =>
      complete &&
      (step == VerificationStep.draft || step == VerificationStep.info);

  /// Les pièces restent modifiables tant que l'équipe n'a pas la main.
  bool get editable =>
      step == VerificationStep.draft || step == VerificationStep.info;

  Verification copyWith({
    Set<ProofKind>? provided,
    VerificationStep? step,
    String? checkId,
    DateTime? submittedAt,
    String? comment,
  }) => Verification(
    provided: provided ?? this.provided,
    step: step ?? this.step,
    checkId: checkId ?? this.checkId,
    submittedAt: submittedAt ?? this.submittedAt,
    comment: comment ?? this.comment,
  );
}

class VerificationNotifier extends Notifier<Verification> {
  @override
  Verification build() {
    // La décision de l'équipe revient sur le dossier du Creator.
    ref.listen(adminProvider.select((s) => s.checks), (_, checks) {
      final id = state.checkId;
      if (id == null) return;
      final c = checks.where((x) => x.id == id).firstOrNull;
      if (c == null) return;
      final step = switch (c.status) {
        VerifyStatus.pending => VerificationStep.pending,
        VerifyStatus.info => VerificationStep.info,
        VerifyStatus.approved => VerificationStep.verified,
        VerifyStatus.rejected => VerificationStep.rejected,
      };
      if (step != state.step) {
        state = state.copyWith(step: step, comment: c.comment);
      }
    });
    if (ref.watch(liveSessionProvider)) return const Verification();
    // Profil de démo : pièce d'identité et portfolio déjà déposés.
    return const Verification(
      provided: {ProofKind.identity, ProofKind.portfolio},
    );
  }

  void toggle(ProofKind k) {
    if (!state.editable) return;
    final set = {...state.provided};
    set.contains(k) ? set.remove(k) : set.add(k);
    state = state.copyWith(provided: set);
  }

  /// Envoie le dossier à l'équipe (ou le renvoie après une demande
  /// d'informations).
  void submit() {
    if (!state.canSubmit) return;
    final admin = ref.read(adminProvider.notifier);
    final existing = state.checkId;
    if (existing != null &&
        ref.read(adminProvider).checks.any((c) => c.id == existing)) {
      admin.decide(existing, VerifyStatus.pending);
    } else {
      final p = ref.read(profileProvider);
      final c = p.creator;
      final id = 'VRF-${2400 + ref.read(adminProvider).checks.length}';
      admin.addCheck(
        VendorCheck(
          id: id,
          business: c?.displayName ?? p.name,
          owner: p.name,
          category: c?.category.label ?? '',
          zone: c?.zone ?? p.city,
          rccm: c?.rccm,
          submitted: DateTime.now(),
          docs: [
            for (final k in ProofKind.values)
              VendorDoc(k._label, DocStatus.submitted),
          ],
        ),
      );
      state = state.copyWith(checkId: id);
    }
    state = state.copyWith(
      step: VerificationStep.pending,
      submittedAt: DateTime.now(),
    );
    ref.read(audienceProvider.notifier).track(Metric.verificationSubmitted);
  }
}

final verificationProvider =
    NotifierProvider<VerificationNotifier, Verification>(
      VerificationNotifier.new,
    );
