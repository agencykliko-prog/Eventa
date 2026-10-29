import 'package:eventa/ui/theme/app_theme.dart';
import 'package:eventa/admin/data/admin_demo.dart';
import 'package:eventa/admin/domain/admin_models.dart';
import 'package:eventa/admin/presentation/admin_providers.dart';
import 'package:eventa/admin/presentation/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Future<ProviderContainer> pumpModule(
    WidgetTester tester,
    AdminModule module, {
    Size size = const Size(375, 812),
    AdminRole role = AdminRole.superAdmin,
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    c
        .read(adminSessionProvider.notifier)
        .signIn(AdminDemo.team.first.copyWith(role: role));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.current(),
          home: AdminShell(module: module),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    return c;
  }

  for (final size in const [Size(375, 812), Size(1280, 860)]) {
    for (final m in AdminModule.values) {
      testWidgets('${m.slug} s’affiche sans débordement à ${size.width}', (
        tester,
      ) async {
        final c = await pumpModule(tester, m, size: size);
        expect(tester.takeException(), isNull);
        expect(find.byType(AdminShell), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }
  }

  testWidgets('un rôle sans permission voit le module verrouillé', (
    tester,
  ) async {
    final c = await pumpModule(
      tester,
      AdminModule.payments,
      size: const Size(1280, 860),
      role: AdminRole.marketing,
    );
    expect(find.textContaining('n’est pas accessible'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  test('la vue d’ensemble est verrouillée pour marketing, service client et modération', () {
    final perms = defaultPermissions();
    for (final r in [
      AdminRole.marketing,
      AdminRole.support,
      AdminRole.moderation,
    ]) {
      expect(perms[r]!.contains(AdminPermission.overview), isFalse);
      expect(AdminModule.homeFor(perms[r]!), isNot(AdminModule.overview));
    }
    expect(
      AdminModule.homeFor(perms[AdminRole.finance]!),
      AdminModule.overview,
    );
  });

  test('résoudre un litige crée le remboursement et trace l’action', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(adminSessionProvider.notifier).signIn(AdminDemo.team.first);
    final n = c.read(adminProvider.notifier);
    final before = c.read(adminProvider).transactions.length;
    n.resolveDispute('EVT-0533', refundPercent: 100);
    final s = c.read(adminProvider);
    expect(
      s.orders.firstWhere((o) => o.ref == 'EVT-0533').status,
      OrderStatus.cancelled,
    );
    expect(s.transactions.length, before + 1);
    expect(s.transactions.first.amount, -350000);
    expect(s.audit.first.action, contains('Litige résolu'));
  });
}
