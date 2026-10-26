import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/domain/models.dart';

enum RequestStatus {
  received('Nouvelle'),
  quoted('Devis envoyé'),
  confirmed('Confirmée'),
  declined('Déclinée');

  const RequestStatus(this.label);
  final String label;
}

/// Demande de devis reçue par un Creator.
@immutable
class ClientRequest {
  const ClientRequest({
    required this.id,
    required this.client,
    required this.eventName,
    required this.category,
    required this.date,
    required this.guests,
    required this.message,
    required this.receivedAt,
    this.avatar,
    this.options = const [],
    this.budget,
    this.status = RequestStatus.received,
    this.quote,
    this.durationMin = 240,
  });

  final String id;
  final String client;
  final String? avatar;
  final String eventName;
  final EventCategory category;

  /// Début de la prestation (date et heure).
  final DateTime date;
  final int durationMin;
  final int guests;
  final String message;
  final List<String> options;
  final int? budget;
  final DateTime receivedAt;
  final RequestStatus status;
  final int? quote;

  ClientRequest copyWith({RequestStatus? status, int? quote}) => ClientRequest(
    id: id,
    client: client,
    avatar: avatar,
    eventName: eventName,
    category: category,
    date: date,
    durationMin: durationMin,
    guests: guests,
    message: message,
    options: options,
    budget: budget,
    receivedAt: receivedAt,
    status: status ?? this.status,
    quote: quote ?? this.quote,
  );
}

class RequestsNotifier extends Notifier<List<ClientRequest>> {
  @override
  List<ClientRequest> build() {
    final n = DateTime.now();
    DateTime d(int days, int h, [int m = 0]) =>
        DateTime(n.year, n.month, n.day + days, h, m);
    return [
      ClientRequest(
        id: 'r1',
        client: 'Awa Traoré',
        avatar: 'assets/images/avatar_1.jpg',
        eventName: 'Mariage Awa & Kouassi',
        category: EventCategory.wedding,
        date: d(42, 14),
        durationMin: 360,
        guests: 250,
        budget: 1300000,
        options: const ['Livraison & installation', 'Arche florale'],
        message: 'Bonjour, nous cherchons une scénographie complète blanc et or pour la réception.',
        receivedAt: n.subtract(const Duration(minutes: 35)),
      ),
      ClientRequest(
        id: 'r2',
        client: 'Yasmine Ouattara',
        avatar: 'assets/images/avatar_5.jpg',
        eventName: 'Les 30 ans de Yasmine',
        category: EventCategory.birthday,
        date: d(27, 18),
        durationMin: 180,
        guests: 60,
        budget: 250000,
        message: 'Déco rooftop thème Gold & Rose, c’est une surprise !',
        receivedAt: n.subtract(const Duration(hours: 5)),
      ),
      ClientRequest(
        id: 'r3',
        client: 'Société Ivoire Digital',
        avatar: 'assets/images/avatar_4.jpg',
        eventName: 'Lancement produit',
        category: EventCategory.pro,
        date: d(9, 9, 30),
        durationMin: 300,
        guests: 120,
        message: 'Habillage de salle et photocall aux couleurs de la marque.',
        receivedAt: n.subtract(const Duration(days: 2)),
        status: RequestStatus.quoted,
        quote: 780000,
      ),
      ClientRequest(
        id: 'r4',
        client: 'Mariam Traoré',
        avatar: 'assets/images/avatar_3.jpg',
        eventName: 'Baby shower de Mariam',
        category: EventCategory.baby,
        date: d(14, 13),
        durationMin: 150,
        guests: 35,
        message: 'Arche de ballons pastel et table sucrée.',
        receivedAt: n.subtract(const Duration(days: 6)),
        status: RequestStatus.confirmed,
        quote: 150000,
      ),
      ClientRequest(
        id: 'r5',
        client: 'Fondation Lumière',
        eventName: 'Gala de charité',
        category: EventCategory.charity,
        date: d(3, 17),
        durationMin: 240,
        guests: 300,
        message: 'Centres de table pour 30 tables rondes.',
        receivedAt: n.subtract(const Duration(days: 12)),
        status: RequestStatus.confirmed,
        quote: 1100000,
      ),
    ];
  }

  void _set(ClientRequest r) =>
      state = [for (final x in state) x.id == r.id ? r : x];

  void sendQuote(String id, int amount) => _set(
    state
        .firstWhere((r) => r.id == id)
        .copyWith(status: RequestStatus.quoted, quote: amount),
  );

  void confirm(String id) => _set(
    state
        .firstWhere((r) => r.id == id)
        .copyWith(status: RequestStatus.confirmed),
  );

  void decline(String id) => _set(
    state
        .firstWhere((r) => r.id == id)
        .copyWith(status: RequestStatus.declined),
  );
}

final requestsProvider =
    NotifierProvider<RequestsNotifier, List<ClientRequest>>(
      RequestsNotifier.new,
    );
