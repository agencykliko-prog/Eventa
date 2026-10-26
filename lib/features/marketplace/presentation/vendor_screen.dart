import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';
import '../../commerce/data/catalog.dart';
import '../../commerce/domain/commerce_models.dart';
import '../../commerce/presentation/commerce_providers.dart';
import '../../events/domain/models.dart';
import '../../events/presentation/events_providers.dart';
import 'widgets/vendor_card.dart';

class VendorScreen extends ConsumerWidget {
  const VendorScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = Catalog.vendor(id);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 320,
            backgroundColor: Confetti.cream,
            automaticallyImplyLeading: false,
            titleSpacing: 12,
            title: Row(
              children: [
                RoundIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Retour',
                  onTap: () => context.pop(),
                ),
                const Spacer(),
                RoundIconButton(
                  icon: AppIcons.share,
                  tooltip: 'Partager',
                  onTap: () => toast(context, 'Lien de la fiche copié'),
                ),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'vendor-${v.id}',
                child: Image.asset(v.image, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Tag(
                        label: v.category.label,
                        hue: Hue.mango,
                        icon: v.category.icon,
                      ),
                      if (v.verified)
                        const Tag(
                          label: 'Vérifié',
                          hue: Hue.violet,
                          icon: AppIcons.verified,
                        ),
                      if (v.sponsor != null) SponsorTag(sponsor: v.sponsor!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(v.name, style: context.text.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    v.tagline,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.eventa.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Stars(rating: v.rating, reviews: v.reviews, size: 14),
                      const SizedBox(width: 12),
                      const Icon(
                        AppIcons.place,
                        size: 15,
                        color: Confetti.inkMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        v.zone,
                        style: context.text.labelMedium?.copyWith(
                          color: context.eventa.muted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        AppIcons.clock,
                        size: 15,
                        color: Confetti.inkMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Répond en ${v.responseTime}',
                        style: context.text.labelMedium?.copyWith(
                          color: context.eventa.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Panel(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tarif',
                                style: context.text.labelSmall?.copyWith(
                                  color: context.eventa.muted,
                                ),
                              ),
                              Text(
                                priceLabel(v),
                                style: context.text.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 34, color: Confetti.line),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Disponibilité',
                                style: context.text.labelSmall?.copyWith(
                                  color: context.eventa.muted,
                                ),
                              ),
                              Text(
                                v.available
                                    ? 'Disponible'
                                    : (v.nextAvailable ?? 'Complet'),
                                style: context.text.titleSmall?.copyWith(
                                  color: v.available
                                      ? Confetti.success
                                      : Confetti.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text('À propos', style: context.text.titleLarge),
                  const SizedBox(height: 8),
                  Text(v.description, style: context.text.bodyLarge),
                  const SizedBox(height: 26),
                  Text('Coordonnées', style: context.text.titleLarge),
                  const SizedBox(height: 10),
                  _InfoList(
                    rows: [
                      (AppIcons.phone, v.phoneNumber),
                      (AppIcons.mail, v.email),
                      (AppIcons.globe, v.website),
                      (AppIcons.place, '${v.zone}, Abidjan'),
                    ],
                  ),
                  if (v.packages.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text('Formules', style: context.text.titleLarge),
                    const SizedBox(height: 10),
                    _InfoList(
                      rows: [for (final p in v.packages) (null, p.name)],
                      captions: [for (final p in v.packages) p.description],
                      trailing: [for (final p in v.packages) fcfa(p.price)],
                    ),
                  ],
                  const SizedBox(height: 26),
                  ReviewsSection(vendor: v),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(vendor: v),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = vendor;
    Widget contact(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
    ) => SizedBox(
      width: 58,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: context.text.labelSmall),
          ],
        ),
      ),
    );
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Confetti.line)),
      ),
      child: Row(
        children: [
          contact(
            AppIcons.phone,
            'Appeler',
            Confetti.ink,
            () => toast(context, 'Appel vers ${v.phone}', icon: AppIcons.phone),
          ),
          contact(
            AppIcons.message,
            'Message',
            Confetti.violet,
            () => _messageSheet(context, v),
          ),
          contact(
            AppIcons.whatsapp,
            'WhatsApp',
            Confetti.success,
            () => toast(
              context,
              'Ouverture de WhatsApp avec ${v.name}',
              icon: AppIcons.whatsapp,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PillButton(
              label: 'Demander un devis',
              height: 50,
              onPressed: () => showQuoteRequestSheet(context, ref, v),
            ),
          ),
        ],
      ),
    );
  }

  void _messageSheet(BuildContext context, Vendor v) {
    final c = TextEditingController(
      text: 'Bonjour, êtes-vous disponible à ma date ?',
    );
    showEventaSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message à ${v.name}', style: ctx.text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Répond généralement en ${v.responseTime}.',
              style: ctx.text.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(controller: c, maxLines: 4, minLines: 3, autofocus: true),
            const SizedBox(height: 14),
            PillButton(
              label: 'Envoyer',
              icon: AppIcons.send,
              tone: ButtonTone.dark,
              onPressed: () {
                Navigator.of(ctx).pop();
                toast(
                  context,
                  'Message envoyé à ${v.name}',
                  icon: AppIcons.send,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Étape 2 : demande de devis personnalisée.
Future<void> showQuoteRequestSheet(
  BuildContext context,
  WidgetRef ref,
  Vendor v,
) async {
  final events = ref.read(eventsProvider).value ?? const <Event>[];
  if (events.isEmpty) {
    toast(context, 'Créez d’abord un événement', icon: AppIcons.info);
    return;
  }
  final bookingId = await showEventaSheet<String>(
    context,
    builder: (_) => _QuoteRequest(vendor: v, events: events),
  );
  if (bookingId != null && context.mounted) {
    context.push(Routes.booking(bookingId));
  }
}

class _QuoteRequest extends ConsumerStatefulWidget {
  const _QuoteRequest({required this.vendor, required this.events});

  final Vendor vendor;
  final List<Event> events;

  @override
  ConsumerState<_QuoteRequest> createState() => _QuoteRequestState();
}

class _QuoteRequestState extends ConsumerState<_QuoteRequest> {
  late Event _event = widget.events.first;
  late double _guests = _event.guests.invited.clamp(10, 500).toDouble();
  late VendorPackage? _package = widget.vendor.packages.isEmpty
      ? null
      : widget.vendor.packages.first;
  TimeOfDay _start = const TimeOfDay(hour: 16, minute: 0);
  String? _budget;
  bool _delivery = false;
  final _address = TextEditingController();
  bool _staff = false;
  int _staffCount = 2;
  bool _tasting = false;
  String _tastingWhen = 'En semaine';
  bool _overtime = false;
  int _hours = 2;
  late final _message = TextEditingController();
  bool _sending = false;

  static const _budgets = [
    'Moins de 250 000 FCFA',
    '250 000 – 500 000 FCFA',
    '500 000 – 1 000 000 FCFA',
    '1 000 000 – 3 000 000 FCFA',
    'Plus de 3 000 000 FCFA',
  ];

  @override
  void initState() {
    super.initState();
    _address.text = _event.venue;
  }

  @override
  void dispose() {
    _message.dispose();
    _address.dispose();
    super.dispose();
  }

  List<String> get _options => [
    if (_package != null) 'Formule : ${_package!.name}',
    'Début : ${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
    if (_budget != null) 'Budget : $_budget',
    if (_delivery)
      'Livraison & installation (${_address.text.trim().isEmpty ? 'adresse à préciser' : _address.text.trim()})',
    if (_staff) 'Personnel supplémentaire × $_staffCount',
    if (_tasting) 'Dégustation ou essai ($_tastingWhen)',
    if (_overtime) 'Heures supplémentaires × $_hours h',
  ];

  Future<void> _send() async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final extras = _options
        .where(
          (o) =>
              !o.startsWith('Formule') &&
              !o.startsWith('Début') &&
              !o.startsWith('Budget'),
        )
        .toList();
    final id = ref
        .read(bookingsProvider.notifier)
        .request(
          widget.vendor,
          _event.id,
          QuoteRequest(
            date: DateTime(
              _event.date.year,
              _event.date.month,
              _event.date.day,
              _start.hour,
              _start.minute,
            ),
            guests: _guests.round(),
            message: [
              if (_message.text.trim().isNotEmpty) _message.text.trim(),
              ..._options,
            ].join('\n'),
            options: extras,
          ),
        );
    if (mounted) Navigator.of(context).pop(id);
  }

  Widget _stepper(
    int value,
    ValueChanged<int> onChanged, {
    int min = 1,
    int max = 20,
    String unit = '',
  }) {
    Widget b(IconData i, VoidCallback? f) => Pressable(
      onTap: f,
      scale: 0.9,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Confetti.line),
        ),
        child: Icon(
          i,
          size: 14,
          color: f == null ? Confetti.inkFaint : Confetti.ink,
        ),
      ),
    );
    return Row(
      children: [
        b(AppIcons.minus, value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 56,
          child: Text(
            '$value$unit',
            textAlign: TextAlign.center,
            style: context.text.titleSmall,
          ),
        ),
        b(AppIcons.add, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demande de devis', style: context.text.headlineSmall),
          Text(
            '${v.name} · gratuit et sans engagement',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 18),
          AppSelect<Event>(
            label: 'Événement',
            value: _event,
            options: widget.events,
            labelOf: (e) => '${e.name} · ${shortDate(e.date)}',
            iconOf: (e) => e.category.icon,
            onChanged: (e) => setState(() {
              _event = e;
              _guests = e.guests.invited.clamp(10, 500).toDouble();
              _address.text = e.venue;
            }),
          ),
          if (v.packages.isNotEmpty) ...[
            const SizedBox(height: 14),
            AppSelect<VendorPackage>(
              label: 'Formule souhaitée',
              value: _package,
              options: v.packages,
              labelOf: (p) => '${p.name} · ${fcfa(p.price)}',
              onChanged: (p) => setState(() => _package = p),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Heure de début'),
                    Pressable(
                      scale: 0.98,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _start,
                        );
                        if (t != null) setState(() => _start = t);
                      },
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Confetti.line),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              AppIcons.clock,
                              size: 18,
                              color: Confetti.inkMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _start.format(context),
                              style: context.text.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Invités'),
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Confetti.line),
                      ),
                      child: Center(
                        child: _stepper(
                          _guests.round(),
                          (n) => setState(() => _guests = n.toDouble()),
                          min: 10,
                          max: 800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppSelect<String>(
            label: 'Budget indicatif',
            value: _budget,
            options: _budgets,
            labelOf: (b) => b,
            optional: true,
            onChanged: (b) => setState(() => _budget = b),
          ),
          const SizedBox(height: 18),
          const FieldLabel('Options'),
          CheckRow(
            label: 'Livraison & installation',
            caption: 'Le prestataire s’installe sur place',
            value: _delivery,
            onChanged: (x) => setState(() => _delivery = x),
            revealed: TextField(
              controller: _address,
              decoration: const InputDecoration(
                hintText: 'Adresse du lieu',
                prefixIcon: Icon(AppIcons.place, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CheckRow(
            label: 'Personnel supplémentaire',
            value: _staff,
            onChanged: (x) => setState(() => _staff = x),
            revealed: Row(
              children: [
                Expanded(
                  child: Text(
                    'Nombre de personnes',
                    style: context.text.bodyMedium,
                  ),
                ),
                _stepper(_staffCount, (n) => setState(() => _staffCount = n)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CheckRow(
            label: 'Dégustation ou essai',
            value: _tasting,
            onChanged: (x) => setState(() => _tasting = x),
            revealed: Wrap(
              spacing: 8,
              children: [
                for (final w in const [
                  'En semaine',
                  'Le week-end',
                  'Peu importe',
                ])
                  ChoiceChip(
                    label: Text(w),
                    selected: _tastingWhen == w,
                    showCheckmark: false,
                    selectedColor: Confetti.ink,
                    labelStyle: context.text.labelMedium?.copyWith(
                      color: _tastingWhen == w ? Colors.white : Confetti.ink,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _tastingWhen == w ? Confetti.ink : Confetti.line,
                    ),
                    onSelected: (_) => setState(() => _tastingWhen = w),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CheckRow(
            label: 'Heures supplémentaires',
            value: _overtime,
            onChanged: (x) => setState(() => _overtime = x),
            revealed: Row(
              children: [
                Expanded(
                  child: Text('Durée en plus', style: context.text.bodyMedium),
                ),
                _stepper(
                  _hours,
                  (n) => setState(() => _hours = n),
                  max: 8,
                  unit: ' h',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppField(
            label: 'Message au prestataire',
            controller: _message,
            optional: true,
            maxLines: 3,
            hint: 'Votre thème, vos contraintes, vos questions…',
          ),
          const SizedBox(height: 20),
          PillButton(
            label: 'Envoyer la demande',
            icon: AppIcons.send,
            loading: _sending,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

/// Liste sobre : une ligne par information, séparateurs fins.
class _InfoList extends StatelessWidget {
  const _InfoList({required this.rows, this.captions, this.trailing});

  final List<(IconData?, String)> rows;
  final List<String>? captions;
  final List<String>? trailing;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  if (rows[i].$1 != null) ...[
                    Icon(rows[i].$1, size: 18, color: Confetti.inkMuted),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].$2, style: context.text.titleSmall),
                        if (captions != null)
                          Text(captions![i], style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    Text(trailing![i], style: context.text.titleSmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Avis vérifiés : la note d'abord, puis chaque avis sur une ligne nette
/// (étoiles, date, commentaire, auteur et statut de vérification).
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key, required this.vendor});

  final Vendor vendor;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final reviews = _all ? Catalog.reviews : Catalog.reviews.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avis vérifiés', style: context.text.titleLarge),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              v.rating.toStringAsFixed(1).replaceAll('.', ','),
              style: context.text.displaySmall?.copyWith(
                fontSize: 40,
                height: 1,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StarRow(rating: v.rating.round(), size: 15),
                  const SizedBox(height: 3),
                  Text(
                    '${v.reviews} avis de clients ayant réservé',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.easeOut,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (final (i, r) in reviews.indexed) ...[
                const Divider(height: 1),
                Entrance(
                  key: ValueKey(r.author),
                  index: i < 3 ? 0 : i - 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StarRow(rating: r.rating, size: 13),
                            const Spacer(),
                            Text(
                              r.when,
                              style: context.text.labelSmall?.copyWith(
                                color: Confetti.inkFaint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(r.text, style: context.text.bodyMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(r.author, style: context.text.labelMedium),
                            const SizedBox(width: 8),
                            const Icon(
                              AppIcons.verified,
                              size: 13,
                              color: Confetti.lagoonText,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Réservation vérifiée',
                              style: context.text.labelSmall?.copyWith(
                                color: Confetti.lagoonText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (Catalog.reviews.length > 3)
          TextButton(
            onPressed: () => setState(() => _all = !_all),
            child: Text(
              _all ? 'Voir moins' : 'Voir les ${Catalog.reviews.length} avis',
              style: context.text.labelMedium?.copyWith(
                color: Confetti.coralDeep,
              ),
            ),
          ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.size});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 5; i++)
        Icon(
          i < rating ? AppIcons.star : AppIcons.starLine,
          size: size,
          color: i < rating ? Confetti.mango : Confetti.inkFaint,
        ),
    ],
  );
}
