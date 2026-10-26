import '../domain/models.dart';
import 'demo_data.dart';

/// Contrat d'accès aux événements. La v1 s'appuie sur des données locales ;
/// une implémentation Supabase prendra le relais sans toucher aux écrans.
abstract interface class EventsRepository {
  Future<List<Event>> fetchEvents();
}

class DemoEventsRepository implements EventsRepository {
  const DemoEventsRepository({
    this.latency = const Duration(milliseconds: 650),
  });

  final Duration latency;

  @override
  Future<List<Event>> fetchEvents() async {
    await Future<void>.delayed(latency);
    return DemoData.events();
  }
}
