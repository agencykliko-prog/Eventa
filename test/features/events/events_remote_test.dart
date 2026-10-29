import 'package:eventa/core/auth/session_provider.dart';
import 'package:eventa/core/auth/profile.dart';
import 'package:eventa/features/events/data/events_remote.dart';
import 'package:eventa/features/events/data/events_repository.dart';
import 'package:eventa/core/models/models.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = '11111111-2222-4333-8444-555555555555';

void main() {
  test('une ligne de la base devient un événement complet', () {
    const repo = SupabaseEventsRepository(userId: _me, userName: 'Awa Koné');
    final e = repo.eventFromRow({
      'id': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      'name': 'Mariage Awa & Kouassi',
      'subtitle': 'Dot · Civil',
      'category': 'wedding',
      'subcategories': ['Dot', 'Mariage civil'],
      'starts_at': '2027-02-14T15:00:00Z',
      'place': 'Espace Latrille Events',
      'city': 'Abidjan',
      'cover_url': null,
      'budget_target': 12000000,
      'guests_expected': 250,
      'budget_lines': [
        {
          'category': 'venue',
          'planned': 3000000,
          'committed': 2500000,
          'paid': 750000,
          'note': null,
        },
        // Catégorie inconnue de cette version de l'app : ignorée.
        {'category': 'fusee', 'planned': 1, 'committed': 0, 'paid': 0},
      ],
      'expenses': [
        {
          'id': 'x1',
          'category': 'venue',
          'label': 'Acompte salle',
          'amount': 750000,
          'paid_at': '2026-10-01T10:00:00Z',
          'method': 'Wave',
          'receipt_ref': 'EVT-2026-1234',
        },
      ],
      'tasks': [
        {
          'id': 't2',
          'title': 'Plan de table',
          'due_at': '2027-02-01T09:00:00Z',
          'done': false,
          'module': 'guests',
          'urgent': false,
          'duration_min': 60,
        },
        {
          'id': 't1',
          'title': 'Réserver la salle',
          'due_at': '2026-11-01T09:00:00Z',
          'done': true,
          'module': 'vendors',
          'urgent': true,
          'duration_min': 30,
        },
      ],
      'guests': [
        {'id': 'g1', 'name': 'Yao', 'rsvp': 'yes', 'companions': 2},
        {'id': 'g2', 'name': 'Adjoua', 'rsvp': 'yes', 'phone': '0707070707'},
        {'id': 'g3', 'name': 'Koffi', 'rsvp': 'no', 'group_name': 'Amis'},
        {'id': 'g4', 'name': 'Bintou', 'rsvp': 'pending'},
      ],
    });

    expect(e.category, EventCategory.wedding);
    expect(e.venue, 'Espace Latrille Events');
    expect(
      e.cover,
      isNotEmpty,
      reason: 'couverture par défaut de la catégorie',
    );
    expect(e.budget, hasLength(1));
    expect(e.paid, 750000);
    expect(e.expenses.single.id, 'EVT-2026-1234');
    expect(e.tasks.map((t) => t.id), [
      't1',
      't2',
    ], reason: 'triées par échéance');
    expect(e.tasks.first.urgent, isTrue);
    expect(e.guests.invited, 4);
    expect(e.guests.confirmed, 2);
    expect(e.guests.declined, 1);
    expect(e.guests.list.map((g) => g.name), [
      'Adjoua',
      'Bintou',
      'Koffi',
      'Yao',
    ], reason: 'triés par nom');
    expect(e.guests.headcount, 4, reason: 'Yao vient avec 2 personnes');
    expect(e.guests.list[2].group, 'Amis');
    expect(e.team.single.id, _me);
  });

  test('sans invités saisis, le nombre prévu est repris', () {
    const repo = SupabaseEventsRepository(userId: _me, userName: 'Awa');
    final e = repo.eventFromRow({
      'id': 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      'name': 'Anniversaire',
      'category': 'birthday',
      'starts_at': '2027-01-10T18:00:00Z',
      'guests_expected': 60,
      'budget_lines': const [],
      'expenses': const [],
      'tasks': const [],
      'guests': const [],
    });
    expect(e.guests.invited, 60);
    expect(e.guests.pending, 60);
  });

  test('identifiants de la base reconnus', () {
    expect(isServerId('aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'), isTrue);
    expect(isServerId('wedding-1730000000000'), isFalse);
  });

  test('en démo, les événements restent fictifs et rien ne part en base', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.organizer);
    expect(c.read(liveSessionProvider), isFalse);
    expect(c.read(eventsRepositoryProvider), isA<DemoEventsRepository>());
  });
}
