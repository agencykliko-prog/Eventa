import 'package:eventa/core/theme/app_theme.dart';
import 'package:eventa/features/about/presentation/about_screen.dart';
import 'package:eventa/features/about/presentation/privacy_screen.dart';
import 'package:eventa/features/about/presentation/terms_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pages = <String, Widget>{
    'conditions générales': const TermsScreen(),
    'confidentialité': const PrivacyScreen(),
    'à propos': const AboutScreen(),
  };

  for (final e in pages.entries) {
    testWidgets('${e.key} s’affiche sur mobile sans débordement', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.current(), home: e.value),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
