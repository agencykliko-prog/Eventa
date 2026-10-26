import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatars.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';
import '../../auth/presentation/session_provider.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../commerce/presentation/payment_sheet.dart';
import '../../events/domain/models.dart';
import '../../events/presentation/events_providers.dart';
import '../../export/export_sheet.dart';
import '../../premium/presentation/paywall.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final plan = ref.watch(planProvider);
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          physics: const BouncingScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Compte', style: context.text.headlineMedium),
            ),
            const SizedBox(height: 18),
            Panel(
              onTap: () => context.push(Routes.editProfile),
              child: Row(
                children: [
                  Avatar(
                    image: p.photoAsset,
                    bytes: p.photoBytes,
                    initials: p.initials,
                    size: 60,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleLarge,
                              ),
                            ),
                            if (!p.isCreator && plan != Plan.free) ...[
                              const SizedBox(width: 8),
                              PremiumBadge(label: plan.label),
                            ],
                          ],
                        ),
                        Text(
                          p.email,
                          style: context.text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${p.phone} · ${p.city}',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(AppIcons.edit, size: 18, color: Confetti.inkMuted),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (p.isCreator)
              NightPanel(
                onTap: () => context.push(Routes.business),
                child: Row(
                  children: [
                    const IconTile(
                      icon: AppIcons.briefcase,
                      hue: Hue.gold,
                      size: 44,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business / Creator',
                            style: context.text.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'CRM, devis, facturation · dès 29 900 FCFA/mois',
                            style: context.text.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      AppIcons.chevron,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ],
                ),
              )
            else
              NightPanel(
                onTap: () => context.push(Routes.premium),
                child: Row(
                  children: [
                    const IconTile(
                      icon: AppIcons.crown,
                      hue: Hue.gold,
                      size: 44,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan == Plan.free
                                ? 'Passer à Premium'
                                : 'Abonnement ${plan.label}',
                            style: context.text.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            plan == Plan.free
                                ? 'IA, coffre-fort, collaboration · dès 2 900 FCFA/mois'
                                : '${fcfa(plan.price)} / mois · gérer',
                            style: context.text.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      AppIcons.chevron,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            if (p.isCreator) ...[
              const SectionTitle('Visibilité'),
              _Group(
                rows: [
                  _Row(
                    AppIcons.megaphone,
                    'Publicité Premium',
                    'Sponsor du mois, mise en avant, résultat sponsorisé',
                    () => context.push(Routes.business),
                  ),
                  _Row(
                    AppIcons.vendors,
                    'Voir ma fiche',
                    'Telle qu’elle apparaît dans Explorer',
                    () => context.push(Routes.editProfile),
                  ),
                ],
              ),
            ] else ...[
              const SectionTitle('Mon activité'),
              _Group(
                rows: [
                  _Row(
                    AppIcons.calendarCheck,
                    'Mes réservations',
                    bookings.isEmpty
                        ? 'Aucune réservation en cours'
                        : '${bookings.length} en cours',
                    () {
                      bookings.isEmpty
                          ? context.go(Routes.explore)
                          : context.push(Routes.booking(bookings.first.id));
                    },
                  ),
                  _Row(
                    AppIcons.lock,
                    'Coffre-fort',
                    'Contrats, devis, factures, photos',
                    () => requirePremium(
                      context,
                      ref,
                      feature: PremiumFeature.vault,
                      onUnlocked: () => context.push(Routes.vault),
                    ),
                  ),
                  _Row(
                    AppIcons.download,
                    'Exporter mes données',
                    'Dépenses, prestataires, paiements (CSV)',
                    () => _pickEventToExport(context, ref),
                  ),
                ],
              ),
            ],
            const SectionTitle('Réglages'),
            _Group(
              rows: [
                _Row(
                  AppIcons.bell,
                  'Notifications',
                  'Push, e-mail, WhatsApp',
                  () => _notificationsSheet(context),
                ),
                if (!p.isCreator)
                  _Row(
                    AppIcons.card,
                    'Moyen de paiement par défaut',
                    'Mobile Money, carte, Apple Pay',
                    () => _paymentSheet(context),
                  ),
                _Row(
                  AppIcons.shield,
                  'Confidentialité',
                  'Visibilité du profil et des données',
                  () => _privacySheet(context),
                ),
                _Row(
                  AppIcons.help,
                  'Aide & support',
                  'Questions fréquentes, nous contacter',
                  () => _helpSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PillButton(
              label: 'Se déconnecter',
              tone: ButtonTone.ghost,
              icon: AppIcons.signOut,
              onPressed: () {
                ref.read(sessionProvider.notifier).signOut();
                context.go(Routes.onboarding);
              },
            ),
            const SizedBox(height: 28),
            const Center(child: EventaWordmark(size: 15)),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Le budget parfait pour célébrer · démo',
                style: context.text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickEventToExport(BuildContext context, WidgetRef ref) async {
    final events = ref.read(eventsProvider).value ?? const <Event>[];
    if (events.isEmpty) return;
    final picked = await showEventaSheet<Event>(
      context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          Text('Quel événement ?', style: ctx.text.headlineSmall),
          const SizedBox(height: 10),
          for (final e in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  e.cover,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(e.name, style: ctx.text.titleSmall),
              subtitle: Text(mediumDate(e.date), style: ctx.text.bodySmall),
              trailing: const Icon(AppIcons.chevron, size: 15),
              onTap: () => Navigator.of(ctx).pop(e),
            ),
        ],
      ),
    );
    if (picked != null && context.mounted) showExportSheet(context, picked.id);
  }

  void _notificationsSheet(BuildContext context) => showEventaSheet<void>(
    context,
    builder: (_) => const _ToggleSheet(
      title: 'Notifications',
      items: [
        ('Notifications push', 'Rappels, devis, paiements', true),
        ('E-mail', 'Récapitulatif hebdomadaire', true),
        ('WhatsApp', 'Rappels importants uniquement', false),
        ('SMS', 'Codes et confirmations', true),
      ],
    ),
  );

  void _privacySheet(BuildContext context) => showEventaSheet<void>(
    context,
    builder: (_) => const _ToggleSheet(
      title: 'Confidentialité',
      items: [
        ('Profil visible des collaborateurs', 'Nom et photo', true),
        ('Partager mes statistiques anonymes', 'Pour améliorer Eventa', false),
        (
          'Afficher mon numéro aux prestataires',
          'Après une demande de devis',
          true,
        ),
      ],
    ),
  );

  void _paymentSheet(BuildContext context) {
    var method = PayMethod.wave;
    showEventaSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moyen de paiement par défaut',
                style: ctx.text.headlineSmall,
              ),
              const SizedBox(height: 14),
              MethodPicker(
                value: method,
                onChanged: (m) => set(() => method = m),
              ),
              const SizedBox(height: 16),
              PillButton(
                label: 'Enregistrer',
                tone: ButtonTone.dark,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  toast(context, '${method.label} défini par défaut');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _helpSheet(BuildContext context) => showEventaSheet<void>(
    context,
    builder: (ctx) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text('Aide & support', style: ctx.text.headlineSmall),
        const SizedBox(height: 8),
        for (final (q, a) in const [
          (
            'Mes paiements sont-ils sécurisés ?',
            'Les fonds sont conservés jusqu’à la validation de la prestation, puis reversés au prestataire.',
          ),
          (
            'Puis-je annuler une réservation ?',
            'Oui, selon les conditions du devis. L’annulation est gratuite jusqu’à J-30 en général.',
          ),
          (
            'Comment inviter un co-organisateur ?',
            'Depuis l’événement, touchez l’icône Partager. Deux collaborateurs sont offerts.',
          ),
        ])
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            title: Text(q, style: ctx.text.titleSmall),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(a, style: ctx.text.bodyMedium),
              ),
            ],
          ),
        const SizedBox(height: 10),
        PillButton(
          label: 'Écrire au support',
          icon: AppIcons.message,
          tone: ButtonTone.dark,
          onPressed: () {
            Navigator.of(ctx).pop();
            toast(
              context,
              'Message envoyé, réponse sous 24 h',
              icon: AppIcons.send,
            );
          },
        ),
      ],
    ),
  );
}

class _Row {
  const _Row(this.icon, this.title, this.caption, this.onTap);
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;
}

class _Group extends StatelessWidget {
  const _Group({required this.rows});

  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Pressable(
              scale: 0.99,
              onTap: rows[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    Icon(rows[i].icon, size: 21, color: Confetti.ink),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].title, style: context.text.titleSmall),
                          Text(rows[i].caption, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(
                      AppIcons.chevron,
                      size: 15,
                      color: Confetti.inkFaint,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleSheet extends StatefulWidget {
  const _ToggleSheet({required this.title, required this.items});

  final String title;
  final List<(String, String, bool)> items;

  @override
  State<_ToggleSheet> createState() => _ToggleSheetState();
}

class _ToggleSheetState extends State<_ToggleSheet> {
  late final _values = [for (final i in widget.items) i.$3];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: context.text.headlineSmall),
          const SizedBox(height: 8),
          for (var i = 0; i < widget.items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.items[i].$1,
                          style: context.text.titleSmall,
                        ),
                        Text(widget.items[i].$2, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  Switch(
                    value: _values[i],
                    onChanged: (v) => setState(() => _values[i] = v),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const FieldLabel(
            'Les préférences sont enregistrées automatiquement.',
          ),
        ],
      ),
    );
  }
}
