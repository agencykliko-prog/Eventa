import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../events/domain/models.dart';
import '../../events/presentation/events_providers.dart';
import '../domain/commerce_models.dart';

// ─── Abonnement ─────────────────────────────────────────────────────────

class PlanNotifier extends Notifier<Plan> {
  @override
  Plan build() => Plan.free;

  void subscribe(Plan p) {
    state = p;
    Future<void>.delayed(
      const Duration(milliseconds: 700),
      () => ref.read(soundProvider).play(Sfx.premium),
    );
  }
}

final planProvider = NotifierProvider<PlanNotifier, Plan>(PlanNotifier.new);

// ─── Abonnement Creator ─────────────────────────────────────────────────

/// Prix mensuel de l'offre Creator.
const creatorPlanPrice = 29900;

/// Abonnement Creator en cours (null : pas d'abonnement).
class CreatorSubscription {
  const CreatorSubscription({
    required this.since,
    required this.renewsOn,
    required this.method,
    required this.receipt,
    this.cancelled = false,
  });

  final DateTime since;
  final DateTime renewsOn;
  final PayMethod method;
  final String receipt;

  /// Résilié : reste actif jusqu'à [renewsOn], sans renouvellement.
  final bool cancelled;

  CreatorSubscription copyWith({bool? cancelled}) => CreatorSubscription(
    since: since,
    renewsOn: renewsOn,
    method: method,
    receipt: receipt,
    cancelled: cancelled ?? this.cancelled,
  );
}

class CreatorSubNotifier extends Notifier<CreatorSubscription?> {
  @override
  CreatorSubscription? build() => null;

  /// Active l'abonnement après un paiement réussi (30 jours).
  void activate(PayMethod method, String receipt) {
    final now = DateTime.now();
    state = CreatorSubscription(
      since: now,
      renewsOn: now.add(const Duration(days: 30)),
      method: method,
      receipt: receipt,
    );
    Future<void>.delayed(
      const Duration(milliseconds: 700),
      () => ref.read(soundProvider).play(Sfx.premium),
    );
  }

  void cancel() => state = state?.copyWith(cancelled: true);
  void resume() => state = state?.copyWith(cancelled: false);
}

final creatorSubProvider =
    NotifierProvider<CreatorSubNotifier, CreatorSubscription?>(
      CreatorSubNotifier.new,
    );

/// Une fonctionnalité est débloquée par l'abonnement.
final featureUnlockedProvider =
    Provider.family<bool, (PremiumFeature, String?)>(
      (ref, arg) => ref.watch(planProvider).includes(arg.$1.minPlan),
    );

// ─── Coffre-fort ────────────────────────────────────────────────────────

class VaultNotifier extends Notifier<List<VaultDoc>> {
  @override
  List<VaultDoc> build() {
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days: d));
    const w = 'mariage-awa-kouassi';
    return [
      VaultDoc(
        name: 'Contrat Espace Latrille Events.pdf'.tr,
        folder: VaultFolder.contracts,
        sizeKb: 412,
        date: ago(40),
        eventId: w,
      ),
      VaultDoc(
        name: 'Contrat Saveurs d’Ivoire.pdf'.tr,
        folder: VaultFolder.contracts,
        sizeKb: 386,
        date: ago(21),
        eventId: w,
      ),
      VaultDoc(
        name: 'Devis Studio Lumière.pdf'.tr,
        folder: VaultFolder.quotes,
        sizeKb: 198,
        date: ago(6),
        eventId: w,
      ),
      VaultDoc(
        name: 'Devis Maison Inès Déco.pdf'.tr,
        folder: VaultFolder.quotes,
        sizeKb: 233,
        date: ago(15),
        eventId: w,
      ),
      VaultDoc(
        name: 'Reçu acompte salle EVT-0412.pdf'.tr,
        folder: VaultFolder.invoices,
        sizeKb: 96,
        date: ago(40),
        eventId: w,
      ),
      VaultDoc(
        name: 'Reçu acompte traiteur EVT-0498.pdf'.tr,
        folder: VaultFolder.invoices,
        sizeKb: 94,
        date: ago(21),
        eventId: w,
      ),
      VaultDoc(
        name: 'Essayage robe — 12 photos'.tr,
        folder: VaultFolder.photos,
        sizeKb: 18400,
        date: ago(3),
        eventId: w,
      ),
      VaultDoc(
        name: 'Certificat de publication des bans.pdf'.tr,
        folder: VaultFolder.certificates,
        sizeKb: 120,
        date: ago(2),
        eventId: w,
      ),
      VaultDoc(
        name: 'Pièces d’identité des témoins.pdf'.tr,
        folder: VaultFolder.documents,
        sizeKb: 840,
        date: ago(9),
        eventId: w,
      ),
    ];
  }

  void add(VaultDoc d) => state = [d, ...state];

  void remove(VaultDoc d) => state = state.where((x) => x != d).toList();
}

final vaultProvider = NotifierProvider<VaultNotifier, List<VaultDoc>>(
  VaultNotifier.new,
);

// ─── Réservations ───────────────────────────────────────────────────────

String receiptRef() => 'EVT-{0}-{1}'.trf([
  DateTime.now().year,
  (math.Random().nextInt(9000) + 1000),
]);

class BookingsNotifier extends Notifier<List<Booking>> {
  @override
  List<Booking> build() => const [];

  Booking byId(String id) => state.firstWhere((b) => b.id == id);

  void _set(Booking b) => state = [for (final x in state) x.id == b.id ? b : x];

  /// Étapes 1 → 2 : demande de devis. Le prestataire (simulé) répond.
  String request(Vendor v, String eventId, QuoteRequest r) {
    final id = 'bk-${DateTime.now().microsecondsSinceEpoch}';
    final b = Booking(
      id: id,
      vendor: v,
      eventId: eventId,
      step: BookingStep.requested,
      request: r,
      createdAt: DateTime.now(),
      messages: [
        ChatMessage(fromMe: true, text: r.message, at: DateTime.now()),
      ],
    );
    state = [b, ...state];
    ref.read(audienceProvider.notifier).track(Metric.quoteRequest);
    ref
        .read(eventsProvider.notifier)
        .upsertVendor(
          eventId,
          EventVendor(vendor: v, status: VendorStatus.contacted, amount: 0),
        );
    Timer(const Duration(milliseconds: 2600), () => _receiveQuote(id));
    return id;
  }

  /// Étape 3 : réception du devis (simulée).
  void _receiveQuote(String id) {
    if (!state.any((b) => b.id == id)) return;
    final b = byId(id);
    final v = b.vendor;
    final perHead = v.unit == 'pers.';
    final base = perHead ? v.priceFrom * b.request.guests : v.priceFrom;
    final lines = <QuoteLine>[
      QuoteLine(
        perHead
            ? '{0} × {1} invités'.trf([
                v.packages.isEmpty ? 'Prestation'.tr : v.packages.first.name,
                b.request.guests,
              ])
            : (v.packages.isEmpty
                  ? 'Prestation {0}'.trf([v.category.label.toLowerCase()])
                  : v.packages.first.name),
        base,
      ),
      for (final o in b.request.options)
        QuoteLine(o, (base * 0.08 / 1000).round() * 1000, optional: true),
      if (v.zone != 'Cocody'.tr && v.zone != 'Plateau'.tr)
        QuoteLine('Déplacement & installation'.tr, 35000),
    ];
    final subtotal = lines.fold<int>(0, (s, l) => s + l.amount);
    final quote = Quote(
      lines: lines,
      fees: (subtotal * 0.02 / 100).round() * 100,
      validUntil: DateTime.now().add(const Duration(days: 7)),
      conditions: [
        'Acompte de 30 % à la réservation, solde à J-7.'.tr,
        'Annulation gratuite jusqu’à J-30 ; ensuite l’acompte est conservé.'.tr,
        'Date bloquée dès le paiement de l’acompte.'.tr,
        'Fonds reversés au prestataire après validation de la prestation.'.tr,
      ],
    );
    _set(
      b.copyWith(
        step: BookingStep.quoted,
        quote: quote,
        messages: [
          ...b.messages,
          ChatMessage(
            fromMe: false,
            text: 'Merci pour votre demande ! Voici notre devis détaillé, valable 7 jours. N’hésitez pas si vous avez des questions.'
                .tr,
            at: DateTime.now(),
          ),
        ],
      ),
    );
    ref
        .read(eventsProvider.notifier)
        .upsertVendor(
          b.eventId,
          EventVendor(
            vendor: v,
            status: VendorStatus.quoted,
            amount: quote.total,
          ),
        );
  }

  /// Négociation par l'agent IA : remise obtenue sur les lignes du devis.
  int negotiate(String id) {
    final b = byId(id);
    final q = b.quote!;
    final lines = [
      for (final l in q.lines)
        QuoteLine(
          l.label,
          (l.amount * 0.93 / 500).round() * 500,
          optional: l.optional,
        ),
    ];
    final next = Quote(
      lines: lines,
      conditions: q.conditions,
      fees: q.fees,
      validUntil: q.validUntil,
      depositRate: q.depositRate,
    );
    _set(
      b.copyWith(
        quote: next,
        messages: [
          ...b.messages,
          ChatMessage(
            fromMe: true,
            text: 'L’agent IA a proposé une remise de 7 % au regard des tarifs du marché.'
                .tr,
            at: DateTime.now(),
          ),
          ChatMessage(
            fromMe: false,
            text: 'C’est d’accord pour nous, devis mis à jour.'.tr,
            at: DateTime.now(),
          ),
        ],
      ),
    );
    return q.total - next.total;
  }

  /// Étape 4 : acceptation, la date est bloquée, l'engagé est mis à jour.
  void accept(String id) {
    final b = byId(id);
    _set(b.copyWith(step: BookingStep.reserved));
    ref.read(audienceProvider.notifier).track(Metric.booking);
    ref.read(soundProvider).play(Sfx.booking);
    final events = ref.read(eventsProvider.notifier);
    events.commit(b.eventId, b.vendor.category.budget, b.quote!.subtotal);
    events.upsertVendor(
      b.eventId,
      EventVendor(
        vendor: b.vendor,
        status: VendorStatus.booked,
        amount: b.quote!.total,
      ),
    );
  }

  /// Étape 5 (acompte) ou 7 (solde) : paiement confirmé, reçu généré.
  Receipt pay(String id, int amount, PayMethod method) {
    final b = byId(id);
    final r = Receipt(
      ref: receiptRef(),
      label: b.paidAmount == 0 && amount < b.balance
          ? 'Acompte {0}'.trf([b.vendor.name])
          : (b.paidAmount == 0
                ? 'Paiement {0}'.trf([b.vendor.name])
                : 'Solde {0}'.trf([b.vendor.name])),
      amount: amount,
      method: method,
      date: DateTime.now(),
      payee: b.vendor.name,
    );
    final paid = b.paidAmount + amount;
    final next = b.step.index < BookingStep.executing.index
        ? BookingStep.executing
        : b.step;
    _set(
      b.copyWith(step: next, paidAmount: paid, receipts: [...b.receipts, r]),
    );
    ref.read(audienceProvider.notifier).track(Metric.payment);

    final events = ref.read(eventsProvider.notifier);
    events.addExpense(
      b.eventId,
      Expense(
        id: r.ref,
        category: b.vendor.category.budget,
        label: r.label,
        amount: amount,
        date: r.date,
        method: method.label,
      ),
    );
    events.upsertVendor(
      b.eventId,
      EventVendor(
        vendor: b.vendor,
        status: paid >= b.quote!.total
            ? VendorStatus.paid
            : VendorStatus.booked,
        amount: b.quote!.total,
      ),
    );
    ref
        .read(vaultProvider.notifier)
        .add(
          VaultDoc(
            name: 'Reçu {0} {1}.pdf'.trf([r.label, r.ref]),
            folder: VaultFolder.invoices,
            sizeKb: 92,
            date: r.date,
            eventId: b.eventId,
          ),
        );
    return r;
  }

  void message(String id, String text) {
    final b = byId(id);
    _set(
      b.copyWith(
        messages: [
          ...b.messages,
          ChatMessage(fromMe: true, text: text, at: DateTime.now()),
        ],
      ),
    );
    ref.read(audienceProvider.notifier).track(Metric.messageSent);
    Timer(const Duration(milliseconds: 1500), () {
      if (!state.any((x) => x.id == id)) return;
      final cur = byId(id);
      _set(
        cur.copyWith(
          messages: [
            ...cur.messages,
            ChatMessage(
              fromMe: false,
              text: 'Bien noté, je reviens vers vous très vite.'.tr,
              at: DateTime.now(),
            ),
          ],
        ),
      );
    });
  }

  /// Étape 7 : clôture — reversement au prestataire après validation.
  void close(String id) {
    final b = byId(id);
    _set(b.copyWith(step: BookingStep.closed, payoutDone: true));
  }

  void review(String id, int rating) => _set(byId(id).copyWith(rating: rating));

  void archive(String id) => _set(byId(id).copyWith(archived: true));
}

final bookingsProvider = NotifierProvider<BookingsNotifier, List<Booking>>(
  BookingsNotifier.new,
);

final bookingProvider = Provider.family<Booking?, String>((ref, id) {
  for (final b in ref.watch(bookingsProvider)) {
    if (b.id == id) return b;
  }
  return null;
});

/// Raccourci : catégorie budgétaire d'une réservation.
extension BookingBudgetX on Booking {
  BudgetCategory get budgetCategory => vendor.category.budget;
}
