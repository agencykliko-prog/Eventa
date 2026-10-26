import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/events_repository.dart';
import '../domain/models.dart';

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => const DemoEventsRepository(),
);

class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() =>
      ref.watch(eventsRepositoryProvider).fetchEvents();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  void _update(String eventId, Event Function(Event) f) {
    final events = state.value;
    if (events == null) return;
    state = AsyncData([for (final e in events) e.id == eventId ? f(e) : e]);
  }

  void toggleTask(String eventId, String taskId) => _update(
    eventId,
    (e) => e.copyWith(
      tasks: [
        for (final t in e.tasks)
          if (t.id == taskId) t.copyWith(done: !t.done) else t,
      ],
    ),
  );

  void addTask(String eventId, EventTask t) =>
      _update(eventId, (e) => e.copyWith(tasks: [...e.tasks, t]));

  void updateTask(String eventId, EventTask t) => _update(
    eventId,
    (e) => e.copyWith(tasks: [for (final x in e.tasks) x.id == t.id ? t : x]),
  );

  void removeTask(String eventId, String taskId) => _update(
    eventId,
    (e) => e.copyWith(tasks: e.tasks.where((x) => x.id != taskId).toList()),
  );

  void add(Event event) {
    final events = state.value ?? const [];
    state = AsyncData([event, ...events]);
  }

  // ─── Budget ──────────────────────────────────────────────────────────

  void setTarget(String eventId, int target) =>
      _update(eventId, (e) => e.copyWith(targetBudget: target));

  void upsertLine(String eventId, BudgetLine line) => _update(eventId, (e) {
    final exists = e.budget.any((l) => l.category == line.category);
    return e.copyWith(
      budget: exists
          ? [for (final l in e.budget) l.category == line.category ? line : l]
          : [...e.budget, line],
    );
  });

  void removeLine(String eventId, BudgetCategory c) => _update(
    eventId,
    (e) => e.copyWith(budget: e.budget.where((l) => l.category != c).toList()),
  );

  void replaceBudget(String eventId, List<BudgetLine> lines) =>
      _update(eventId, (e) => e.copyWith(budget: lines));

  /// Une dépense réglée augmente le payé du poste (et l'engagé s'il le faut).
  void addExpense(String eventId, Expense x) => _update(eventId, (e) {
    final line =
        e.line(x.category) ?? BudgetLine(category: x.category, estimated: 0);
    final paid = line.paid + x.amount;
    final updated = line.copyWith(
      paid: paid,
      committed: paid > line.committed ? paid : line.committed,
    );
    final exists = e.budget.any((l) => l.category == x.category);
    return e.copyWith(
      expenses: [x, ...e.expenses],
      budget: exists
          ? [for (final l in e.budget) l.category == x.category ? updated : l]
          : [...e.budget, updated],
    );
  });

  /// Une réservation acceptée crée ou met à jour l'engagé du poste.
  void commit(String eventId, BudgetCategory c, int amount) =>
      _update(eventId, (e) {
        final line = e.line(c) ?? BudgetLine(category: c, estimated: amount);
        final updated = line.copyWith(committed: line.committed + amount);
        final exists = e.budget.any((l) => l.category == c);
        return e.copyWith(
          budget: exists
              ? [for (final l in e.budget) l.category == c ? updated : l]
              : [...e.budget, updated],
        );
      });

  // ─── Équipe ──────────────────────────────────────────────────────────

  void addMember(String eventId, TeamMember m) =>
      _update(eventId, (e) => e.copyWith(team: [...e.team, m]));

  void updateMember(String eventId, TeamMember m) => _update(
    eventId,
    (e) => e.copyWith(team: [for (final x in e.team) x.id == m.id ? m : x]),
  );

  void removeMember(String eventId, String memberId) => _update(
    eventId,
    (e) => e.copyWith(team: e.team.where((x) => x.id != memberId).toList()),
  );

  // ─── Prestataires ────────────────────────────────────────────────────

  void upsertVendor(String eventId, EventVendor v) => _update(eventId, (e) {
    final exists = e.vendors.any((x) => x.vendor.id == v.vendor.id);
    return e.copyWith(
      vendors: exists
          ? [for (final x in e.vendors) x.vendor.id == v.vendor.id ? v : x]
          : [...e.vendors, v],
    );
  });
}

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<Event>>(
  EventsNotifier.new,
);

/// Un événement précis, à partir de la liste.
final eventProvider = Provider.family<AsyncValue<Event?>, String>((ref, id) {
  return ref.watch(eventsProvider).whenData((events) {
    for (final e in events) {
      if (e.id == id) return e;
    }
    return null;
  });
});
