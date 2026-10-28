import 'package:eventa/app.dart';
import 'package:eventa/features/auth/domain/profile.dart';
import 'package:eventa/features/auth/presentation/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: EventaApp()));
    await tester.pump(const Duration(milliseconds: 1500));
  }

  testWidgets('accueil → inscription, avec le choix Organisateur / Creator', (
    tester,
  ) async {
    await start(tester);
    expect(
      find.textContaining('Le budget parfait', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Créer un compte'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Organisateur'), findsOneWidget);
    expect(find.text('Creator'), findsOneWidget);
    expect(find.text('Nom et prénom'), findsOneWidget);

    // Le profil Creator affiche l'inscription professionnelle en 3 étapes.
    await tester.tap(find.text('Creator'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Informations professionnelles'), findsOneWidget);
    expect(find.text('Prestataire indépendant'), findsOneWidget);
  });

  test('la session Creator donne un profil Creator', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(sessionProvider.notifier).signIn(UserRole.creator);
    expect(c.read(profileProvider).isCreator, isTrue);
    expect(c.read(profileProvider).creator?.category, isNotNull);
    c.read(sessionProvider.notifier).signOut();
    expect(c.read(sessionProvider), isNull);
  });
}
