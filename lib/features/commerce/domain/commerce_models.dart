import 'package:flutter/widgets.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../events/domain/models.dart';

// ─── Paiements ──────────────────────────────────────────────────────────

enum PayMethod {
  orange('Orange Money', AppIcons.mobile, Color(0xFFFF7900), true),
  mtn('MTN Money', AppIcons.mobile, Color(0xFFFFCB05), true),
  wave('Wave', AppIcons.mobile, Color(0xFF1DC4FF), true),
  moov('Moov Money', AppIcons.mobile, Color(0xFF0066B3), true),
  card('Carte bancaire', AppIcons.card, Confetti.ink, false),
  applePay('Apple Pay', AppIcons.apple, Confetti.ink, false),
  googlePay('Google Pay', AppIcons.google, Confetti.ink, false);

  const PayMethod(this.label, this.icon, this.dot, this.mobileMoney);
  final String label;
  final IconData icon;

  /// Pastille d'identification (pas de logo de marque).
  final Color dot;
  final bool mobileMoney;
}

@immutable
class Receipt {
  const Receipt({
    required this.ref,
    required this.label,
    required this.amount,
    required this.method,
    required this.date,
    required this.payee,
    this.fees = 0,
  });

  final String ref;
  final String label;
  final int amount;
  final int fees;
  final PayMethod method;
  final DateTime date;
  final String payee;

  int get total => amount + fees;
}

// ─── Réservation : 7 étapes ─────────────────────────────────────────────

enum BookingStep {
  selected('Choix', 'Prestataire choisi'),
  requested('Demande', 'Devis demandé'),
  quoted('Devis', 'Devis reçu'),
  reserved('Résa.', 'Date bloquée'),
  paid('Paiement', 'Acompte réglé'),
  executing('Exécution', 'Préparation en cours'),
  closed('Clôture', 'Dossier clôturé');

  const BookingStep(this.label, this.status);
  final String label;
  final String status;
}

@immutable
class QuoteRequest {
  const QuoteRequest({
    required this.date,
    required this.guests,
    required this.message,
    this.options = const [],
    this.budget,
  });

  final DateTime date;
  final int guests;
  final String message;
  final List<String> options;
  final int? budget;
}

@immutable
class QuoteLine {
  const QuoteLine(this.label, this.amount, {this.optional = false});
  final String label;
  final int amount;
  final bool optional;
}

@immutable
class Quote {
  const Quote({
    required this.lines,
    required this.conditions,
    required this.fees,
    required this.validUntil,
    this.depositRate = 0.3,
  });

  final List<QuoteLine> lines;
  final List<String> conditions;

  /// Frais de service plateforme.
  final int fees;
  final DateTime validUntil;
  final double depositRate;

  int get subtotal => lines.fold(0, (s, l) => s + l.amount);
  int get total => subtotal + fees;
  int get deposit => (total * depositRate / 500).round() * 500;
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.fromMe,
    required this.text,
    required this.at,
  });
  final bool fromMe;
  final String text;
  final DateTime at;
}

@immutable
class Booking {
  const Booking({
    required this.id,
    required this.vendor,
    required this.eventId,
    required this.step,
    required this.request,
    required this.createdAt,
    this.quote,
    this.paidAmount = 0,
    this.receipts = const [],
    this.messages = const [],
    this.payoutDone = false,
    this.rating,
    this.archived = false,
  });

  final String id;
  final Vendor vendor;
  final String eventId;
  final BookingStep step;
  final QuoteRequest request;
  final DateTime createdAt;
  final Quote? quote;
  final int paidAmount;
  final List<Receipt> receipts;
  final List<ChatMessage> messages;
  final bool payoutDone;
  final int? rating;
  final bool archived;

  int get balance => (quote?.total ?? 0) - paidAmount;
  bool get fullyPaid => quote != null && balance <= 0;

  Booking copyWith({
    BookingStep? step,
    Quote? quote,
    int? paidAmount,
    List<Receipt>? receipts,
    List<ChatMessage>? messages,
    bool? payoutDone,
    int? rating,
    bool? archived,
  }) => Booking(
    id: id,
    vendor: vendor,
    eventId: eventId,
    step: step ?? this.step,
    request: request,
    createdAt: createdAt,
    quote: quote ?? this.quote,
    paidAmount: paidAmount ?? this.paidAmount,
    receipts: receipts ?? this.receipts,
    messages: messages ?? this.messages,
    payoutDone: payoutDone ?? this.payoutDone,
    rating: rating ?? this.rating,
    archived: archived ?? this.archived,
  );
}

// ─── Abonnements ────────────────────────────────────────────────────────

enum Plan {
  free('Découverte', 0, Hue.ink),
  azur('Azur', 2900, Hue.lagoon),
  signature('Signature', 5900, Hue.violet),
  privilege('Privilège', 9900, Hue.gold);

  const Plan(this.label, this.price, this.hue);
  final String label;
  final int price;
  final Hue hue;

  bool includes(Plan other) => index >= other.index;
}

/// Fonctionnalités soumises à un abonnement, et le niveau minimal requis.
enum PremiumFeature {
  aiBudget('Budget créé par l’IA', Plan.azur, AppIcons.sparkle),
  collaborators('Plus de 2 collaborateurs', Plan.azur, AppIcons.userPlus),
  agent('Agent IA de votre événement', Plan.signature, AppIcons.sparkle),
  vault('Coffre-fort numérique', Plan.signature, AppIcons.lock);

  const PremiumFeature(this.label, this.minPlan, this.icon);
  final String label;
  final Plan minPlan;
  final IconData icon;
}

// ─── Coffre-fort ────────────────────────────────────────────────────────

enum VaultFolder {
  contracts('Contrats', AppIcons.contract),
  quotes('Devis', AppIcons.file),
  invoices('Factures & reçus', AppIcons.invoice),
  photos('Photos', AppIcons.images),
  certificates('Certificats', AppIcons.certificate),
  documents('Documents', AppIcons.folder);

  const VaultFolder(this.label, this.icon);
  final String label;
  final IconData icon;
}

@immutable
class VaultDoc {
  const VaultDoc({
    required this.name,
    required this.folder,
    required this.sizeKb,
    required this.date,
    this.eventId,
  });

  final String name;
  final VaultFolder folder;
  final int sizeKb;
  final DateTime date;
  final String? eventId;
}

extension BookingEventX on Booking {
  bool belongsTo(Event e) => eventId == e.id;
}
