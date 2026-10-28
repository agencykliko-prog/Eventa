import 'package:eventa/core/analytics/analytics.dart';
import 'package:eventa/core/router/app_router.dart';
import 'package:eventa/features/admin/domain/admin_models.dart';
import 'package:eventa/features/admin/presentation/admin_providers.dart';
import 'package:eventa/features/auth/domain/profile.dart';
import 'package:eventa/features/auth/presentation/session_provider.dart';
import 'package:eventa/features/commerce/data/catalog.dart';
import 'package:eventa/features/commerce/domain/commerce_models.dart';
import 'package:eventa/features/commerce/presentation/commerce_providers.dart';
import 'package:eventa/features/events/data/events_repository.dart';
import 'package:eventa/features/events/presentation/events_providers.dart';
import 'package:eventa/features/inbox/inbox_providers.dart';
import 'package:eventa/features/notifications/notifications_provider.dart';
import 'package:eventa/features/pro/presentation/verification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Messagerie, notifications, vérification des prestataires et mesure
// d'audience : les quatre briques qui font tourner la plateforme.

ProviderContainer _container(UserRole role) {
  final c = ProviderContainer(
    overrides: [
      eventsRepositoryProvider.overrideWithValue(
        const DemoEventsRepository(latency: Duration.zero),
      ),
    ],
  );
  addTearDown(c.dispose);
  c.read(sessionProvider.notifier).signIn(role);
  // Garde les notifications actives, comme la cloche de l'accueil.
  c.listen(noticesProvider, (_, _) {});
  return c;
}

void main() {
  test(
    'Creator : message non lu, réponse du client, notification et audience',
    () async {
      final c = _container(UserRole.creator);

      // Yasmine a répondu à la question du Creator : 1 message non lu.
      expect(c.read(unreadInProvider('r2')), 1);
      expect(c.read(unreadMessagesProvider), 1);
      c
          .read(readMarksProvider.notifier)
          .seen(c.read(conversationProvider('r2'))!);
      expect(c.read(unreadMessagesProvider), 0);

      final noticesBefore = c.read(unreadNoticesProvider);
      c.read(messengerProvider).send('r2', 'Parfait, merci !');
      final sent = c.read(conversationProvider('r2'))!.messages.last;
      expect(sent.fromMe, isTrue);
      expect(sent.text, 'Parfait, merci !');

      // La réponse simulée arrive : message non lu et notification.
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(c.read(unreadMessagesProvider), 1);
      expect(c.read(unreadNoticesProvider), noticesBefore + 1);
      final notice = c.read(noticesProvider).first;
      expect(notice.title, 'Nouveau message');
      expect(notice.link, Routes.conversation('r2'));

      c.read(noticesProvider.notifier).markAllRead();
      expect(c.read(unreadNoticesProvider), 0);

      final audience = c.read(audienceSummaryProvider);
      expect(audience.events[Metric.signIn], 1);
      expect(audience.events[Metric.messageSent], 1);
    },
  );

  test(
    'organisateur : la demande de devis ouvre une conversation et notifie',
    () async {
      final c = _container(UserRole.organizer);
      expect(c.read(conversationsProvider), isEmpty);

      final events = await c.read(eventsProvider.future);
      final id = c
          .read(bookingsProvider.notifier)
          .request(
            Catalog.vendor('studio-lumiere'),
            events.first.id,
            QuoteRequest(
              date: events.first.date,
              guests: 80,
              message: 'Bonjour',
            ),
          );
      expect(c.read(conversationsProvider).single.id, id);
      expect(c.read(unreadInProvider(id)), 0);

      await Future<void>.delayed(const Duration(milliseconds: 2800));
      final notice = c.read(noticesProvider).first;
      expect(notice.title, 'Devis reçu');
      expect(notice.link, Routes.booking(id));
      expect(notice.read, isFalse);
      // Le message du prestataire qui accompagne le devis est non lu.
      expect(c.read(unreadInProvider(id)), 1);
      expect(c.read(audienceSummaryProvider).events[Metric.quoteRequest], 1);
    },
  );

  test(
    'organisateur : un message depuis la fiche ouvre une conversation',
    () async {
      final c = _container(UserRole.organizer);
      final v = Catalog.vendor('studio-lumiere');
      c.read(directThreadsProvider.notifier).send(v, 'Êtes-vous libre le 12 ?');
      final id = directConversationId(v);
      expect(c.read(conversationProvider(id))!.messages.single.fromMe, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 1700));
      expect(c.read(unreadInProvider(id)), 1);
      expect(c.read(noticesProvider).first.link, Routes.conversation(id));

      // La réponse depuis la messagerie reste dans la même conversation.
      c.read(messengerProvider).send(id, 'Parfait, je réserve.');
      expect(c.read(conversationProvider(id))!.messages, hasLength(3));
    },
  );

  test('vérification : dossier envoyé, infos demandées, renvoi puis badge', () {
    final c = _container(UserRole.creator);
    final n = c.read(verificationProvider.notifier);
    expect(c.read(verificationProvider).step, VerificationStep.draft);
    expect(c.read(verificationProvider).canSubmit, isFalse);

    n.submit(); // incomplet : ignoré
    expect(c.read(verificationProvider).checkId, isNull);

    for (final k in [ProofKind.rccm, ProofKind.address, ProofKind.payout]) {
      n.toggle(k);
    }
    n.submit();
    final v = c.read(verificationProvider);
    expect(v.step, VerificationStep.pending);
    final check = c.read(adminProvider).checks.first;
    expect(check.id, v.checkId);
    expect(check.status, VerifyStatus.pending);
    expect(check.docs, hasLength(ProofKind.values.length));

    // L'équipe demande une précision depuis le centre de contrôle.
    final admin = c.read(adminProvider.notifier);
    admin.decide(check.id, VerifyStatus.info, comment: 'RCCM illisible');
    expect(c.read(verificationProvider).step, VerificationStep.info);
    expect(c.read(verificationProvider).comment, 'RCCM illisible');
    expect(c.read(noticesProvider).first.title, 'Informations demandées');

    // Renvoi : le même dossier repasse « À vérifier ».
    n.submit();
    expect(c.read(verificationProvider).step, VerificationStep.pending);
    expect(c.read(adminProvider).checks.first.status, VerifyStatus.pending);
    expect(
      c.read(adminProvider).checks.where((x) => x.id == check.id),
      hasLength(1),
    );

    admin.decide(check.id, VerifyStatus.approved);
    expect(c.read(verificationProvider).step, VerificationStep.verified);
    expect(c.read(verificationProvider).editable, isFalse);
    expect(c.read(noticesProvider).first.title, 'Profil vérifié');
    expect(
      c.read(audienceSummaryProvider).events[Metric.verificationSubmitted],
      2,
    );
  });

  test(
    'mesure d’audience : écrans dédoublonnés et retrait du consentement',
    () {
      final c = _container(UserRole.organizer);
      final a = c.read(audienceProvider.notifier);
      a.screen('/accueil');
      a.screen('/accueil');
      a.screen('/prestataire/:id');
      a.screen('/accueil');
      final s = c.read(audienceSummaryProvider);
      expect(s.pageViews, 3);
      expect(s.topScreens.first, ('/accueil', 2));

      c.read(audienceConsentProvider.notifier).set(false);
      expect(c.read(audienceProvider), isEmpty);
      a.screen('/explorer');
      a.track(Metric.payment);
      expect(c.read(audienceProvider), isEmpty);
    },
  );
}
