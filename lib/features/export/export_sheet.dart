import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/eventa_colors.dart';
import '../../core/utils/download_stub.dart'
    if (dart.library.js_interop) '../../core/utils/download_web.dart';
import '../../core/widgets/forms.dart';
import '../../core/widgets/ui.dart';
import '../commerce/presentation/commerce_providers.dart';
import '../events/domain/models.dart';
import '../events/presentation/events_providers.dart';

enum ExportKind {
  expenses('Dépenses', 'Poste, libellé, montant, date'),
  vendors('Prestataires', 'Nom, catégorie, statut, montant, contacts'),
  payments('Paiements', 'Référence, bénéficiaire, moyen, montant');

  const ExportKind(this.label, this.caption);
  final String label;
  final String caption;
}

/// Construit les fichiers CSV (séparateur « ; », lisible par Excel FR).
abstract final class Exporter {
  static String _row(List<Object?> cells) => cells
      .map((c) => '"${(c ?? '').toString().replaceAll('"', '""')}"')
      .join(';');

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String expenses(Event e) => [
    _row(['Événement', 'Poste', 'Libellé', 'Montant (FCFA)', 'Date', 'Moyen']),
    for (final x in e.expenses)
      _row([
        e.name,
        x.category.label,
        x.label,
        x.amount,
        _date(x.date),
        x.method,
      ]),
  ].join('\n');

  static String vendors(Event e) => [
    _row([
      'Événement',
      'Prestataire',
      'Catégorie',
      'Statut',
      'Montant (FCFA)',
      'Téléphone',
      'E-mail',
      'Site web',
    ]),
    for (final v in e.vendors)
      _row([
        e.name,
        v.vendor.name,
        v.vendor.category.label,
        v.status.label,
        v.amount,
        v.vendor.phoneNumber,
        v.vendor.email,
        v.vendor.website,
      ]),
  ].join('\n');

  static String payments(Event e, WidgetRef ref) {
    final receipts = [
      for (final b in ref.read(bookingsProvider))
        if (b.eventId == e.id) ...b.receipts,
    ];
    final fromBookings = {for (final r in receipts) r.ref};
    return [
      _row([
        'Événement',
        'Référence',
        'Objet',
        'Bénéficiaire',
        'Moyen',
        'Montant (FCFA)',
        'Date',
      ]),
      for (final r in receipts)
        _row([
          e.name,
          r.ref,
          r.label,
          r.payee,
          r.method.label,
          r.total,
          _date(r.date),
        ]),
      for (final x in e.expenses)
        if (!fromBookings.contains(x.id))
          _row([
            e.name,
            x.id,
            x.label,
            x.category.label,
            x.method,
            x.amount,
            _date(x.date),
          ]),
    ].join('\n');
  }
}

Future<void> showExportSheet(
  BuildContext context,
  String eventId, {
  ExportKind? only,
}) => showEventaSheet<void>(
  context,
  builder: (_) => _ExportSheet(eventId: eventId, only: only),
);

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({required this.eventId, this.only});

  final String eventId;
  final ExportKind? only;

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  late final _kinds = widget.only == null
      ? ExportKind.values.toSet()
      : {widget.only!};
  bool _busy = false;

  Future<void> _export(Event e) async {
    setState(() => _busy = true);
    final slug = e.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    var downloaded = true;
    for (final k in ExportKind.values.where(_kinds.contains)) {
      final csv = switch (k) {
        ExportKind.expenses => Exporter.expenses(e),
        ExportKind.vendors => Exporter.vendors(e),
        ExportKind.payments => Exporter.payments(e, ref),
      };
      downloaded =
          await saveTextFile('eventa-$slug-${k.name}.csv', csv) && downloaded;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    toast(
      context,
      downloaded
          ? '${_kinds.length} fichier${_kinds.length > 1 ? 's' : ''} CSV téléchargé${_kinds.length > 1 ? 's' : ''}'
          : 'Données copiées dans le presse-papiers',
      icon: AppIcons.download,
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = ref.watch(eventProvider(widget.eventId)).value;
    if (e == null) return const SizedBox();
    final counts = {
      ExportKind.expenses: e.expenses.length,
      ExportKind.vendors: e.vendors.length,
      ExportKind.payments: e.expenses.length,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exporter', style: context.text.headlineSmall),
          Text(
            '${e.name} · format CSV (Excel, Numbers, Sheets)',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final k in ExportKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CheckRow(
                label: '${k.label} · ${counts[k]}',
                caption: k.caption,
                value: _kinds.contains(k),
                onChanged: (v) =>
                    setState(() => v ? _kinds.add(k) : _kinds.remove(k)),
              ),
            ),
          const SizedBox(height: 12),
          PillButton(
            label: 'Télécharger',
            icon: AppIcons.download,
            tone: ButtonTone.dark,
            loading: _busy,
            onPressed: _kinds.isEmpty ? null : () => _export(e),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Montants en FCFA, séparateur point-virgule',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
