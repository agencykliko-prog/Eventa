import 'backend.dart';

/// Paiements SasPay. L'app ne voit jamais la clé SasPay : elle demande une
/// page de paiement aux Edge Functions, puis fait vérifier le résultat.
abstract final class PaymentsApi {
  /// Acompte (`deposit`) ou solde (`balance`) d'une réservation.
  static Future<Checkout> payBooking(
    String bookingId, {
    bool balance = false,
  }) => _checkout({
    'purpose': balance ? 'balance' : 'deposit',
    'booking_id': bookingId,
  });

  /// Abonnement d'un mois : `premium` (azur, signature, privilege) ou
  /// `creator` (business).
  static Future<Checkout> subscribe(String product, String plan) =>
      _checkout({'purpose': 'subscription', 'product': product, 'plan': plan});

  /// Statut vérifié chez SasPay : `pending`, `succeeded`, `failed`.
  /// Seul `succeeded` signifie que l'argent est encaissé.
  static Future<String> verify(String paymentId) async {
    final res = await Backend.client.functions.invoke(
      'saspay-verify',
      body: {'payment_id': paymentId},
    );
    return (res.data as Map)['status'] as String;
  }

  static Future<Checkout> _checkout(Map<String, dynamic> body) async {
    final res = await Backend.client.functions.invoke(
      'saspay-checkout',
      body: body,
    );
    final data = res.data as Map;
    return Checkout(
      data['payment_id'] as String,
      Uri.parse(data['checkout_url'] as String),
    );
  }
}

/// Page de paiement SasPay à ouvrir (Wave, Orange Money, MTN, Moov, carte).
class Checkout {
  const Checkout(this.paymentId, this.url);

  final String paymentId;
  final Uri url;
}
