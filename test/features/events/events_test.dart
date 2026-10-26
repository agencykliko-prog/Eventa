import 'package:eventa/core/utils/formatters.dart';
import 'package:eventa/features/events/data/demo_data.dart';
import 'package:eventa/features/events/data/event_templates.dart';
import 'package:eventa/features/events/data/events_repository.dart';
import 'package:eventa/features/events/domain/models.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('Budget', () {
    final e = DemoData.wedding();

    test('les indicateurs suivent le cahier des charges', () {
      expect(e.targetBudget, 12500000);
      expect(e.committed, 8500000);
      expect(e.paid, 4250000);
      expect(e.remainingToPay, e.committed - e.paid);
      expect(e.available, e.targetBudget - e.committed);
      expect((e.committedRatio * 100).round(), 68);
    });

    test('le prévu de démonstration tombe pile sur la cible', () {
      expect(e.estimated, e.targetBudget);
    });
  });

  group('Formats', () {
    test('FCFA avec espaces', () {
      expect(fcfa(12500000), '12 500 000 FCFA');
      expect(fcfaCompact(12500000), '12,5 M');
      expect(fcfaCompact(450000), '450 k');
    });

    test('compte à rebours', () {
      final in42 = DateTime.now().add(const Duration(days: 42));
      expect(countdownLabel(in42), 'J-42');
      expect(countdownLabel(DateTime.now()), 'Jour J');
    });
  });

  test('un modèle génère une checklist à rebours et un budget réparti', () {
    final date = DateTime.now().add(const Duration(days: 200));
    final e = EventTemplates.create(
      category: EventCategory.wedding,
      subcategories: const ['Dot', 'Mariage civil'],
      name: 'Test',
      date: date,
      city: 'Abidjan',
      guests: 100,
      budget: 10000000,
    );
    expect(e.tasks, isNotEmpty);
    expect(e.tasks.every((t) => !t.due.isAfter(date)), isTrue);
    expect((e.estimated - 10000000).abs(), lessThan(50000));
  });

  test('cocher une tâche met à jour la progression', () async {
    final container = ProviderContainer(
      overrides: [
        eventsRepositoryProvider.overrideWithValue(
          const DemoEventsRepository(latency: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    final events = await container.read(eventsProvider.future);
    final wedding = events.firstWhere(
      (e) => e.category == EventCategory.wedding,
    );
    final open = wedding.tasks.firstWhere((t) => !t.done);

    container.read(eventsProvider.notifier).toggleTask(wedding.id, open.id);

    final after = container.read(eventProvider(wedding.id)).value!;
    expect(after.tasksDone, wedding.tasksDone + 1);
  });
}
