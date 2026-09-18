import 'package:go_router/go_router.dart';

import '../../features/brokers/broker_detail_screen.dart';
import '../../features/brokers/brokers_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/inquiries/inquiries_screen.dart';
import '../../features/inquiries/inquiry_form_screen.dart';
import '../../features/listings/listing_detail_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/main_shell.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/accueil',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/accueil',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recherche',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/courtiers',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BrokersScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/demandes',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: InquiriesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/bien/:id',
        builder: (context, state) =>
            ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/courtier/:id',
        builder: (context, state) =>
            BrokerDetailScreen(brokerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/demande/nouvelle',
        builder: (context, state) => InquiryFormScreen(
          listingId: state.uri.queryParameters['listingId'],
        ),
      ),
    ],
  );
}
