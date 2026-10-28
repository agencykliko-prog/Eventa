import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../data/admin_demo.dart';
import '../domain/admin_models.dart';

/// État complet du centre de contrôle (démo locale, sans backend).
@immutable
class AdminState {
  const AdminState({
    required this.accounts,
    required this.checks,
    required this.categories,
    required this.listings,
    required this.orders,
    required this.transactions,
    required this.pricing,
    required this.promos,
    required this.campaigns,
    required this.tickets,
    required this.team,
    required this.permissions,
    required this.audit,
    required this.settings,
  });

  final List<Account> accounts;
  final List<VendorCheck> checks;
  final List<CatalogCategory> categories;
  final List<Listing> listings;
  final List<Order> orders;
  final List<Transaction> transactions;
  final PricingModel pricing;
  final List<PromoCode> promos;
  final List<Campaign> campaigns;
  final List<Ticket> tickets;
  final List<AdminMember> team;
  final Map<AdminRole, Set<AdminPermission>> permissions;
  final List<AuditEntry> audit;

  /// Paramètres plateforme (interrupteurs).
  final Map<String, bool> settings;

  AdminState copyWith({
    List<Account>? accounts,
    List<VendorCheck>? checks,
    List<CatalogCategory>? categories,
    List<Listing>? listings,
    List<Order>? orders,
    List<Transaction>? transactions,
    PricingModel? pricing,
    List<PromoCode>? promos,
    List<Campaign>? campaigns,
    List<Ticket>? tickets,
    List<AdminMember>? team,
    Map<AdminRole, Set<AdminPermission>>? permissions,
    List<AuditEntry>? audit,
    Map<String, bool>? settings,
  }) => AdminState(
    accounts: accounts ?? this.accounts,
    checks: checks ?? this.checks,
    categories: categories ?? this.categories,
    listings: listings ?? this.listings,
    orders: orders ?? this.orders,
    transactions: transactions ?? this.transactions,
    pricing: pricing ?? this.pricing,
    promos: promos ?? this.promos,
    campaigns: campaigns ?? this.campaigns,
    tickets: tickets ?? this.tickets,
    team: team ?? this.team,
    permissions: permissions ?? this.permissions,
    audit: audit ?? this.audit,
    settings: settings ?? this.settings,
  );

  // ─── Indicateurs ────────────────────────────────────────────────────

  int get clients =>
      accounts.where((a) => a.kind == AccountKind.organizer).length;
  int get pros => accounts.where((a) => a.kind == AccountKind.creator).length;

  Iterable<Transaction> get _today {
    final d = dateOnly(DateTime.now());
    return transactions.where((t) => !t.at.isBefore(d));
  }

  /// Volume du jour (paiements et abonnements réussis).
  int get volumeToday => _today
      .where(
        (t) =>
            t.status == TxStatus.success &&
            (t.kind == TxKind.payment || t.kind == TxKind.subscription),
      )
      .fold(0, (s, t) => s + t.amount);

  int get refundsToday => _today
      .where((t) => t.kind == TxKind.refund && t.status == TxStatus.success)
      .fold(0, (s, t) => s - t.amount);

  int get revenueToday => _today
      .where((t) => t.status == TxStatus.success)
      .fold(0, (s, t) => s + t.commission);

  int get revenueTotal => transactions
      .where((t) => t.status == TxStatus.success)
      .fold(0, (s, t) => s + t.commission);

  List<AdminAlert> get alerts => [
    for (final o in orders.where((o) => o.status == OrderStatus.dispute))
      AdminAlert(
        kind: AlertKind.dispute,
        title: 'Litige · ${o.ref}',
        detail: o.dispute ?? '',
        route: 'reservations',
        critical: true,
      ),
    if (transactions.where((t) => t.status == TxStatus.failed).length >= 2)
      AdminAlert(
        kind: AlertKind.anomaly,
        title: 'Paiements échoués',
        detail:
            '${transactions.where((t) => t.status == TxStatus.failed).length} échecs récents, surtout Mobile Money',
        route: 'paiements',
      ),
    if (transactions.where((t) => !t.reconciled).length > 5)
      AdminAlert(
        kind: AlertKind.incident,
        title: 'Rapprochement en retard',
        detail:
            '${transactions.where((t) => !t.reconciled).length} transactions non rapprochées',
        route: 'paiements',
      ),
    if (checks.any((c) => c.status == VerifyStatus.pending))
      AdminAlert(
        kind: AlertKind.verification,
        title: 'Prestataires à vérifier',
        detail:
            '${checks.where((c) => c.status == VerifyStatus.pending).length} dossiers en attente',
        route: 'verification',
      ),
    for (final t in tickets.where(
      (t) =>
          t.priority == TicketPriority.urgent &&
          t.status != TicketStatus.resolved,
    ))
      AdminAlert(
        kind: AlertKind.support,
        title: 'Ticket urgent · ${t.id}',
        detail: t.subject,
        route: 'support',
        critical: true,
      ),
  ];
}

class AdminController extends Notifier<AdminState> {
  @override
  AdminState build() => AdminState(
    accounts: AdminDemo.accounts,
    checks: AdminDemo.checks,
    categories: AdminDemo.categories,
    listings: AdminDemo.listings,
    orders: AdminDemo.orders,
    transactions: AdminDemo.transactions(),
    pricing: const PricingModel(),
    promos: AdminDemo.promos,
    campaigns: AdminDemo.campaigns,
    tickets: AdminDemo.tickets,
    team: AdminDemo.team,
    permissions: defaultPermissions(),
    audit: AdminDemo.audit,
    settings: const {
      'Double authentification obligatoire': true,
      'Inscriptions ouvertes': true,
      'Vérification avant publication': true,
      'Mode maintenance': false,
      'Paiement par carte bancaire': true,
    },
  );

  String get _actor => ref.read(adminSessionProvider)?.name ?? 'Système';

  AdminState _log(AdminState s, String action, String target) => s.copyWith(
    audit: [
      AuditEntry(
        at: DateTime.now(),
        actor: _actor,
        action: action,
        target: target,
      ),
      ...s.audit,
    ],
  );

  List<T> _replace<T>(List<T> l, bool Function(T) where, T Function(T) f) => [
    for (final x in l) where(x) ? f(x) : x,
  ];

  /// Inscrit une action libre au journal d'audit.
  void note(String action, String target) =>
      state = _log(state, action, target);

  // ─── Comptes ────────────────────────────────────────────────────────

  void setAccountStatus(String id, AccountStatus st, {String? reason}) {
    final a = state.accounts.firstWhere((a) => a.id == id);
    state = _log(
      state.copyWith(
        accounts: _replace(
          state.accounts,
          (x) => x.id == id,
          (x) => x.copyWith(status: st, note: reason),
        ),
      ),
      switch (st) {
        AccountStatus.suspended => 'Compte suspendu',
        AccountStatus.active => 'Compte rétabli',
        AccountStatus.pending => 'Compte mis en attente',
      },
      '$id · ${a.name}',
    );
  }

  void updateAccount(Account a) => state = _log(
    state.copyWith(
      accounts: _replace(state.accounts, (x) => x.id == a.id, (_) => a),
    ),
    'Compte modifié',
    '${a.id} · ${a.name}',
  );

  void createAccount(Account a) => state = _log(
    state.copyWith(accounts: [a, ...state.accounts]),
    'Compte créé',
    '${a.id} · ${a.name}',
  );

  // ─── Vérification ───────────────────────────────────────────────────

  /// Dossier envoyé par un prestataire depuis l'app.
  void addCheck(VendorCheck c) => state = _log(
    state.copyWith(checks: [c, ...state.checks]),
    'Dossier de vérification reçu',
    '${c.id} · ${c.business}',
  );

  void setDoc(String checkId, int index, DocStatus st) {
    final c = state.checks.firstWhere((c) => c.id == checkId);
    final docs = [...c.docs];
    docs[index] = docs[index].withStatus(st);
    state = state.copyWith(
      checks: _replace(
        state.checks,
        (x) => x.id == checkId,
        (x) => x.copyWith(docs: docs),
      ),
    );
  }

  void decide(String checkId, VerifyStatus st, {String? comment}) {
    final c = state.checks.firstWhere((c) => c.id == checkId);
    var s = state.copyWith(
      checks: _replace(
        state.checks,
        (x) => x.id == checkId,
        (x) => x.copyWith(status: st, comment: comment),
      ),
    );
    // Un prestataire vérifié voit son compte activé.
    if (st == VerifyStatus.approved) {
      s = s.copyWith(
        accounts: _replace(
          s.accounts,
          (a) => a.name == c.business,
          (a) => a.copyWith(status: AccountStatus.active),
        ),
      );
    }
    state = _log(s, 'Vérification : ${st.label}', '${c.id} · ${c.business}');
  }

  // ─── Catalogue ──────────────────────────────────────────────────────

  void saveCategory(CatalogCategory c) {
    final exists = state.categories.any((x) => x.id == c.id);
    state = _log(
      state.copyWith(
        categories: exists
            ? _replace(state.categories, (x) => x.id == c.id, (_) => c)
            : [...state.categories, c],
      ),
      exists ? 'Catégorie modifiée' : 'Catégorie créée',
      c.name,
    );
  }

  void toggleCategory(String id) {
    final c = state.categories.firstWhere((x) => x.id == id);
    saveCategory(c.copyWith(visible: !c.visible));
  }

  void setListing(String id, ListingStatus st) {
    final l = state.listings.firstWhere((x) => x.id == id);
    state = _log(
      state.copyWith(
        listings: _replace(
          state.listings,
          (x) => x.id == id,
          (x) => x.copyWith(status: st),
        ),
      ),
      'Annonce : ${st.label.toLowerCase()}',
      '$id · ${l.title}',
    );
  }

  // ─── Réservations ───────────────────────────────────────────────────

  void resolveDispute(String ref, {required int refundPercent}) {
    final o = state.orders.firstWhere((x) => x.ref == ref);
    final refund = (o.amount * refundPercent / 100).round();
    var s = state.copyWith(
      orders: _replace(
        state.orders,
        (x) => x.ref == ref,
        (x) => x.copyWith(
          status: refundPercent == 100
              ? OrderStatus.cancelled
              : OrderStatus.completed,
          note: refundPercent == 0
              ? 'Litige clos sans remboursement'
              : 'Litige clos : remboursement de ${fcfa(refund)} ($refundPercent %)',
        ),
      ),
    );
    if (refund > 0) {
      s = s.copyWith(
        transactions: [
          Transaction(
            ref: 'RB-${ref.substring(4)}',
            at: DateTime.now(),
            kind: TxKind.refund,
            method: 'Mobile Money',
            amount: -refund,
            commission: 0,
            status: TxStatus.success,
            party: o.client,
          ),
          ...s.transactions,
        ],
      );
    }
    state = _log(s, 'Litige résolu ($refundPercent %)', '$ref · ${o.client}');
  }

  void cancelOrder(String ref) {
    final o = state.orders.firstWhere((x) => x.ref == ref);
    state = _log(
      state.copyWith(
        orders: _replace(
          state.orders,
          (x) => x.ref == ref,
          (x) => x.copyWith(
            status: OrderStatus.cancelled,
            note: 'Annulée par l’administration',
          ),
        ),
      ),
      'Réservation annulée',
      '$ref · ${o.vendor}',
    );
  }

  // ─── Paiements ──────────────────────────────────────────────────────

  void addTransaction(Transaction t) => state = state.copyWith(
    transactions: [t, ...state.transactions].take(200).toList(),
  );

  void refund(String ref) {
    final t = state.transactions.firstWhere((x) => x.ref == ref);
    state = _log(
      state.copyWith(
        transactions: [
          Transaction(
            ref: 'RB-${ref.substring(3)}',
            at: DateTime.now(),
            kind: TxKind.refund,
            method: t.method,
            amount: -t.amount.abs(),
            commission: -t.commission,
            status: TxStatus.success,
            party: t.party,
          ),
          ...state.transactions,
        ],
      ),
      'Remboursement émis',
      '$ref · ${fcfa(t.amount.abs())}',
    );
  }

  void retry(String ref) {
    state = _log(
      state.copyWith(
        transactions: _replace(
          state.transactions,
          (x) => x.ref == ref,
          (x) => x.copyWith(status: TxStatus.success),
        ),
      ),
      'Paiement relancé',
      ref,
    );
  }

  void reconcileAll() {
    final n = state.transactions.where((t) => !t.reconciled).length;
    state = _log(
      state.copyWith(
        transactions: [
          for (final t in state.transactions)
            t.status == TxStatus.success ? t.copyWith(reconciled: true) : t,
        ],
      ),
      'Rapprochement validé',
      '$n transactions',
    );
  }

  // ─── Modèle économique ──────────────────────────────────────────────

  void setPricing(PricingModel p, String what) =>
      state = _log(state.copyWith(pricing: p), 'Tarification modifiée', what);

  // ─── Marketing ──────────────────────────────────────────────────────

  void addPromo(PromoCode p) => state = _log(
    state.copyWith(promos: [p, ...state.promos]),
    'Code promo créé',
    '${p.code} · -${p.percent} %',
  );

  void togglePromo(String code) {
    final p = state.promos.firstWhere((x) => x.code == code);
    state = _log(
      state.copyWith(
        promos: _replace(
          state.promos,
          (x) => x.code == code,
          (x) => x.copyWith(active: !x.active),
        ),
      ),
      p.active ? 'Code promo désactivé' : 'Code promo activé',
      code,
    );
  }

  void addCampaign(Campaign c) => state = _log(
    state.copyWith(campaigns: [c, ...state.campaigns]),
    'Campagne créée',
    c.name,
  );

  void launchCampaign(String id) {
    final c = state.campaigns.firstWhere((x) => x.id == id);
    state = _log(
      state.copyWith(
        campaigns: _replace(
          state.campaigns,
          (x) => x.id == id,
          (x) => x.copyWith(status: CampaignStatus.running, sent: 2400),
        ),
      ),
      'Campagne lancée',
      c.name,
    );
  }

  // ─── Service client ─────────────────────────────────────────────────

  void assign(String id, String who) {
    state = _log(
      state.copyWith(
        tickets: _replace(
          state.tickets,
          (x) => x.id == id,
          (x) => x.copyWith(
            assignee: who,
            status: x.status == TicketStatus.open
                ? TicketStatus.progress
                : x.status,
          ),
        ),
      ),
      'Ticket attribué',
      '$id → $who',
    );
  }

  void reply(String id, String text, {bool resolve = false}) {
    state = _log(
      state.copyWith(
        tickets: _replace(
          state.tickets,
          (x) => x.id == id,
          (x) => x.copyWith(
            message: text,
            assignee: x.assignee ?? _actor,
            status: resolve ? TicketStatus.resolved : TicketStatus.waiting,
          ),
        ),
      ),
      resolve ? 'Ticket résolu' : 'Réponse envoyée',
      id,
    );
  }

  // ─── Sécurité ───────────────────────────────────────────────────────

  void togglePermission(AdminRole role, AdminPermission p) {
    final set = {...state.permissions[role]!};
    set.contains(p) ? set.remove(p) : set.add(p);
    state = _log(
      state.copyWith(permissions: {...state.permissions, role: set}),
      set.contains(p) ? 'Permission accordée' : 'Permission retirée',
      '${role.label} · ${p.label}',
    );
  }

  void setMemberRole(String id, AdminRole role) {
    final m = state.team.firstWhere((x) => x.id == id);
    state = _log(
      state.copyWith(
        team: _replace(
          state.team,
          (x) => x.id == id,
          (x) => x.copyWith(role: role),
        ),
      ),
      'Rôle modifié',
      '${m.name} → ${role.label}',
    );
  }

  void toggleSetting(String key) => state = _log(
    state.copyWith(
      settings: {...state.settings, key: !(state.settings[key] ?? false)},
    ),
    state.settings[key] == true ? 'Paramètre désactivé' : 'Paramètre activé',
    key,
  );
}

final adminProvider = NotifierProvider<AdminController, AdminState>(
  AdminController.new,
);

/// Membre de l'équipe connecté au centre de contrôle (`null` = déconnecté).
class AdminSession extends Notifier<AdminMember?> {
  @override
  AdminMember? build() => null;

  void signIn(AdminMember m) => state = m;

  /// Démo : permet de voir l'interface avec les droits d'un autre rôle.
  void actAs(AdminRole role) => state = state?.copyWith(role: role);

  void signOut() => state = null;
}

final adminSessionProvider = NotifierProvider<AdminSession, AdminMember?>(
  AdminSession.new,
);

/// Le membre connecté a-t-il cette permission ?
final adminCanProvider = Provider.family<bool, AdminPermission>((ref, p) {
  final me = ref.watch(adminSessionProvider);
  if (me == null) return false;
  final perms = ref.watch(adminProvider.select((s) => s.permissions));
  return perms[me.role]?.contains(p) ?? false;
});

/// Flux temps réel simulé : une transaction toutes les 4 à 9 secondes,
/// tant qu'un écran d'administration l'écoute.
final liveFeedProvider = Provider.autoDispose<void>((ref) {
  final r = math.Random();
  Timer? timer;
  void schedule() {
    timer = Timer(Duration(milliseconds: 4000 + r.nextInt(5000)), () {
      ref.read(adminProvider.notifier).addTransaction(AdminDemo.randomTx(r));
      schedule();
    });
  }

  schedule();
  ref.onDispose(() => timer?.cancel());
});
