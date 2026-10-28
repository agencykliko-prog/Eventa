import 'package:eventa/core/theme/app_theme.dart';
import 'package:eventa/features/admin/presentation/admin_providers.dart';
import 'package:eventa/features/auth/domain/profile.dart';
import 'package:eventa/features/auth/presentation/session_provider.dart';
import 'package:eventa/features/inbox/inbox_screen.dart';
import 'package:eventa/features/pro/presentation/verification_providers.dart';
import 'package:eventa/features/pro/presentation/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<ProviderContainer> pumpApp(WidgetTester tester, String initial) async {
    tester.view.physicalSize = const Size(430, 932) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.creator);
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/messages', builder: (_, _) => const InboxScreen()),
        GoRoute(
          path: '/messages/:id',
          builder: (_, s) => ConversationScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/pro/verification',
          builder: (_, _) => const VerificationScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: AppTheme.current(),
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
    return c;
  }

  testWidgets('messagerie Creator : ouvrir, lire, répondre', (tester) async {
    await pumpApp(tester, '/messages');

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Yasmine Ouattara'), findsOneWidget);
    // Badge du message non lu de Yasmine.
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('conv-r2')));
    await settle(tester);
    expect(
      find.text('Oui, une partie est couverte. Accès possible dès 14 h.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('composer')),
      'Je passe jeudi pour le repérage.',
    );
    await tester.tap(find.byKey(const ValueKey('send')));
    await settle(tester);
    expect(find.text('Je passe jeudi pour le repérage.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(
      find.text(
        'Merci pour votre message, je regarde et je reviens vers vous.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('vérification : déposer les pièces puis envoyer le dossier', (
    tester,
  ) async {
    final c = await pumpApp(tester, '/pro/verification');

    expect(find.text('Faites vérifier votre profil'), findsOneWidget);
    final list = find.byType(Scrollable).first;
    final submit = find.byKey(const ValueKey('verification-submit'));
    await tester.scrollUntilVisible(submit, 200, scrollable: list);
    await settle(tester);
    expect(find.text('Encore 3 pièce(s) à déposer'), findsOneWidget);

    for (final k in ['rccm', 'address', 'payout']) {
      final b = find.byKey(ValueKey('proof-$k'));
      await tester.scrollUntilVisible(b, -200, scrollable: list);
      await tester.tap(b);
      await settle(tester);
    }
    await tester.scrollUntilVisible(submit, 200, scrollable: list);
    await settle(tester);
    expect(find.text('Envoyer le dossier'), findsOneWidget);
    await tester.tap(submit);
    await settle(tester);

    expect(c.read(verificationProvider).step, VerificationStep.pending);
    await tester.scrollUntilVisible(
      find.text('Dossier en cours de vérification'),
      -200,
      scrollable: list,
    );
    expect(find.text('Dossier en cours de vérification'), findsOneWidget);
    expect(
      c.read(adminProvider).checks.first.id,
      c.read(verificationProvider).checkId,
    );
    // Les pièces ne sont plus modifiables pendant le contrôle.
    expect(find.byKey(const ValueKey('proof-rccm')), findsNothing);
  });
}
