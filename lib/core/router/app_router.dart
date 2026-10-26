import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/about_screen.dart';
import '../../features/about/presentation/privacy_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_providers.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/account/presentation/edit_profile_screen.dart';
import '../../features/agent/presentation/agent_screen.dart';
import '../../features/auth/domain/profile.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/session_provider.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/budget/presentation/budget_screen.dart';
import '../../features/create_event/presentation/create_event_screen.dart';
import '../../features/creator/presentation/creator_home_screen.dart';
import '../../features/creator/presentation/requests_screen.dart';
import '../../features/dashboard/presentation/event_dashboard_screen.dart';
import '../../features/events/domain/models.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/marketplace/presentation/explore_screen.dart';
import '../../features/marketplace/presentation/vendor_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/planning/presentation/planning_screen.dart';
import '../../features/premium/presentation/business_screen.dart';
import '../../features/pro/presentation/availability_screen.dart';
import '../../features/pro/presentation/orders_screen.dart';
import '../../features/pro/presentation/profile_catalog_screen.dart';
import '../../features/pro/presentation/reputation_screen.dart';
import '../../features/pro/presentation/request_detail_screen.dart';
import '../../features/pro/presentation/revenue_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/vault/presentation/vault_screen.dart';
import '../theme/eventa_colors.dart';

abstract final class Routes {
  static const onboarding = '/bienvenue';
  static const signIn = '/connexion';
  static const signUp = '/inscription';
  static const home = '/accueil';
  static const explore = '/explorer';
  static const requests = '/demandes';
  static const planning = '/agenda';
  static const account = '/compte';
  static const editProfile = '/compte/profil';
  static const newEvent = '/nouvel-evenement';
  static const premium = '/premium';
  static const business = '/business';
  static const vault = '/coffre-fort';
  static const about = '/a-propos';
  static const privacy = '/confidentialite';
  static const admin = '/admin';
  static String event(String id) => '/evenement/$id';
  static String budget(String id) => '/evenement/$id/budget';
  static String tasks(String id) => '/evenement/$id/taches';
  static String agent(String id) => '/evenement/$id/agent';
  static String vendor(String id) => '/prestataire/$id';
  static String booking(String id) => '/reservation/$id';
  static String exploreCategory(VendorCategory c) =>
      '/explorer?categorie=${c.name}';
}

final _rootKey = GlobalKey<NavigatorState>();

/// Pages hors navigation principale : largeur de lecture bornée sur grand écran.
Widget _bounded(Widget child) => ColoredBox(
  color: Confetti.cream,
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: child,
    ),
  ),
);

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<UserProfile?>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);
  ref.onDispose(session.dispose);
  final adminSession = ValueNotifier<AdminMember?>(
    ref.read(adminSessionProvider),
  );
  ref.listen(adminSessionProvider, (_, next) => adminSession.value = next);
  ref.onDispose(adminSession.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.onboarding,
    refreshListenable: Listenable.merge([session, adminSession]),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Centre de contrôle : session d'équipe distincte des comptes clients.
      if (loc == Routes.admin || loc.startsWith('${Routes.admin}/')) {
        final member = adminSession.value;
        if (member == null && loc != Routes.admin) return Routes.admin;
        if (member != null && loc == Routes.admin) {
          return adminPath(AdminModule.overview);
        }
        return null;
      }
      // La politique de confidentialité reste lisible, connecté ou non.
      if (loc == Routes.privacy) return null;
      final public =
          loc == Routes.onboarding ||
          loc.startsWith(Routes.signIn) ||
          loc.startsWith(Routes.signUp);
      final user = session.value;
      if (user == null && !public) return Routes.onboarding;
      if (user != null && public) return Routes.home;
      // Chaque profil n'accède qu'à ses écrans.
      if (user != null &&
          user.isCreator &&
          (loc.startsWith(Routes.explore) ||
              loc == Routes.premium ||
              loc == Routes.newEvent)) {
        return Routes.home;
      }
      if (user != null &&
          !user.isCreator &&
          (loc.startsWith(Routes.requests) ||
              loc == Routes.business ||
              loc.startsWith('/pro/'))) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.admin,
        pageBuilder: (c, s) => _fade(s, const AdminLoginScreen()),
      ),
      GoRoute(
        path: '/admin/:module',
        pageBuilder: (c, s) => _fade(
          s,
          AdminShell(module: AdminModule.fromSlug(s.pathParameters['module'])),
        ),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (c, s) => _fade(s, const OnboardingScreen()),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (c, s) => AuthScreen(
          role: s.uri.queryParameters['profil'] == 'creator'
              ? UserRole.creator
              : UserRole.organizer,
        ),
      ),
      GoRoute(
        path: Routes.signUp,
        builder: (c, s) => AuthScreen(
          signUp: true,
          role: s.uri.queryParameters['profil'] == 'creator'
              ? UserRole.creator
              : UserRole.organizer,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                pageBuilder: (c, s) => _fade(
                  s,
                  Consumer(
                    builder: (context, ref, _) =>
                        ref.watch(profileProvider).isCreator
                        ? const CreatorHomeScreen()
                        : const HomeScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.explore,
                builder: (c, s) {
                  final cat = s.uri.queryParameters['categorie'];
                  return ExploreScreen(
                    key: ValueKey(s.uri.toString()),
                    initialCategory: cat == null
                        ? null
                        : VendorCategory.values
                              .where((v) => v.name == cat)
                              .firstOrNull,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.requests,
                builder: (c, s) => const RequestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.planning,
                builder: (c, s) => const PlanningScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (c, s) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.editProfile,
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const EditProfileScreen()),
      ),
      GoRoute(
        path: Routes.newEvent,
        parentNavigatorKey: _rootKey,
        pageBuilder: (c, s) => MaterialPage(
          key: s.pageKey,
          fullscreenDialog: true,
          child: _bounded(const CreateEventScreen()),
        ),
      ),
      GoRoute(
        path: Routes.premium,
        parentNavigatorKey: _rootKey,
        pageBuilder: (c, s) => MaterialPage(
          key: s.pageKey,
          fullscreenDialog: true,
          child: const PremiumScreen(),
        ),
      ),
      GoRoute(
        path: Routes.business,
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const BusinessScreen()),
      ),
      // Espace professionnel du Creator.
      GoRoute(
        path: '/pro/profil',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const ProfileCatalogScreen()),
      ),
      GoRoute(
        path: '/pro/disponibilites',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const AvailabilityScreen()),
      ),
      GoRoute(
        path: '/pro/devis/:id',
        parentNavigatorKey: _rootKey,
        builder: (c, s) =>
            _bounded(RequestDetailScreen(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/pro/commandes',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const OrdersScreen()),
      ),
      GoRoute(
        path: '/pro/revenus',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const RevenueScreen()),
      ),
      GoRoute(
        path: '/pro/reputation',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const ReputationScreen()),
      ),
      GoRoute(
        path: Routes.about,
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const AboutScreen()),
      ),
      GoRoute(
        path: Routes.privacy,
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const PrivacyScreen()),
      ),
      GoRoute(
        path: Routes.vault,
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(const VaultScreen()),
      ),
      GoRoute(
        path: '/prestataire/:id',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(VendorScreen(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/reservation/:id',
        parentNavigatorKey: _rootKey,
        builder: (c, s) => _bounded(BookingScreen(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/evenement/:id',
        parentNavigatorKey: _rootKey,
        builder: (c, s) =>
            _bounded(EventDashboardScreen(id: s.pathParameters['id']!)),
        routes: [
          GoRoute(
            path: 'budget',
            builder: (c, s) =>
                _bounded(BudgetScreen(id: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'taches',
            builder: (c, s) =>
                _bounded(TasksScreen(id: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'agent',
            builder: (c, s) =>
                _bounded(AgentScreen(eventId: s.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState s, Widget child) =>
    CustomTransitionPage(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (c, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: child,
      ),
    );
