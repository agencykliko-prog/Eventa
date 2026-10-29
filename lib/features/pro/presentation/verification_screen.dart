import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ui.dart';
import 'pro_widgets.dart';
import 'verification_providers.dart';

extension VerificationStepHue on VerificationStep {
  Hue get hue => switch (this) {
    VerificationStep.draft => Hue.ink,
    VerificationStep.pending => Hue.mango,
    VerificationStep.info => Hue.coral,
    VerificationStep.verified => Hue.lagoon,
    VerificationStep.rejected => Hue.coral,
  };

  IconData get icon => switch (this) {
    VerificationStep.verified => AppIcons.verified,
    VerificationStep.pending => AppIcons.hourglass,
    VerificationStep.info || VerificationStep.rejected => AppIcons.warning,
    VerificationStep.draft => AppIcons.shield,
  };
}

/// H. Vérification : pièces justificatives, envoi du dossier à l'équipe,
/// suivi de la décision et badge « Vérifié ».
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(verificationProvider);
    final n = ref.read(verificationProvider.notifier);
    final missing = ProofKind.values.length - v.provided.length;

    final (title, caption) = switch (v.step) {
      VerificationStep.draft => (
        'Faites vérifier votre profil'.tr,
        'Les organisateurs réservent plus volontiers un prestataire vérifié. Déposez vos pièces puis envoyez le dossier.'
            .tr,
      ),
      VerificationStep.pending => (
        'Dossier en cours de vérification'.tr,
        'Envoyé le {0}. Notre équipe contrôle vos pièces ; vous recevrez une notification dès la décision.'
            .trf([mediumDate(v.submittedAt ?? DateTime.now())]),
      ),
      VerificationStep.info => (
        'Informations demandées'.tr,
        v.comment ?? 'Complétez votre dossier puis renvoyez-le.'.tr,
      ),
      VerificationStep.verified => (
        'Profil vérifié'.tr,
        'Le badge « Vérifié » apparaît sur votre fiche et dans les résultats de recherche.'
            .tr,
      ),
      VerificationStep.rejected => (
        'Vérification refusée'.tr,
        v.comment ?? 'Contactez l’équipe pour en savoir plus.'.tr,
      ),
    };

    return ProPage(
      title: 'Vérification'.tr,
      subtitle: 'Identité, existence légale et compte de reversement.'.tr,
      children: [
        const SizedBox(height: 4),
        Panel(
          key: const ValueKey('verification-status'),
          color: v.step.hue.tint,
          border: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: v.step.icon, hue: v.step.hue, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tag(label: v.step.label, hue: v.step.hue),
                    const SizedBox(height: 8),
                    Text(title, style: context.text.titleMedium),
                    const SizedBox(height: 4),
                    Text(caption, style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionTitle(
          'Pièces justificatives'.tr,
          action: '{0}/{1}'.trf([v.provided.length, ProofKind.values.length]),
        ),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (final (i, k) in ProofKind.values.indexed) ...[
                if (i > 0) const Divider(height: 1),
                _ProofRow(
                  kind: k,
                  provided: v.provided.contains(k),
                  editable: v.editable,
                  onTap: () {
                    final had = v.provided.contains(k);
                    n.toggle(k);
                    toast(
                      context,
                      had ? 'Document retiré'.tr : 'Document ajouté'.tr,
                      icon: had ? AppIcons.trash : AppIcons.checkCircle,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Vos pièces ne servent qu’à la vérification et ne sont jamais affichées sur votre fiche.'
              .tr,
          style: context.text.bodySmall?.copyWith(color: Confetti.inkMuted),
        ),
        if (v.editable) ...[
          const SizedBox(height: 18),
          PillButton(
            key: const ValueKey('verification-submit'),
            label: v.canSubmit
                ? (v.step == VerificationStep.info
                      ? 'Renvoyer le dossier'.tr
                      : 'Envoyer le dossier'.tr)
                : 'Encore {0} pièce(s) à déposer'.trf([missing]),
            icon: AppIcons.send,
            onPressed: v.canSubmit
                ? () {
                    n.submit();
                    toast(
                      context,
                      'Dossier envoyé à l’équipe Calandix'.tr,
                      icon: AppIcons.send,
                    );
                  }
                : null,
          ),
        ],
      ],
    );
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({
    required this.kind,
    required this.provided,
    required this.editable,
    required this.onTap,
  });

  final ProofKind kind;
  final bool provided;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            provided ? AppIcons.checkCircle : AppIcons.file,
            size: 22,
            color: provided ? Confetti.lagoon : Confetti.inkFaint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kind.label, style: context.text.titleSmall),
                Text(kind.hint, style: context.text.bodySmall),
              ],
            ),
          ),
          if (editable)
            PillButton(
              key: ValueKey('proof-${kind.name}'),
              label: provided ? 'Retirer'.tr : 'Ajouter'.tr,
              icon: provided ? null : AppIcons.upload,
              tone: provided ? ButtonTone.ghost : ButtonTone.dark,
              expand: false,
              height: 36,
              onPressed: onTap,
            ),
        ],
      ),
    );
  }
}
