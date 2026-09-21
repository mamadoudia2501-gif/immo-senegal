import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../features/admin/admin_advertisers_screen.dart';
import '../../features/admin/admin_listings_screen.dart';
import '../../features/admin/admin_stories_screen.dart';
import '../../features/auth/phone_auth_screen.dart';
import '../../features/auth/whatsapp_code_screen.dart';
import '../../features/brokers/broker_detail_screen.dart';
import '../../features/brokers/brokers_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/inquiries/inquiries_screen.dart';
import '../../features/inquiries/inquiry_form_screen.dart';
import '../../features/listings/create_listing_screen.dart';
import '../../features/listings/listing_detail_screen.dart';
import '../../features/profile/advertiser_profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/stories/create_story_screen.dart';
import '../../features/stories/story_viewer_screen.dart';
import 'fade_slide_page.dart';

GoRouter createRouter(AuthRepository auth) {
  return GoRouter(
    initialLocation: '/accueil',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/annonce/nouvelle' && !auth.isLoggedIn) {
        return '/connexion?next=/annonce/nouvelle';
      }
      if (path.startsWith('/admin/') && !auth.isAdmin) {
        return auth.isLoggedIn ? '/profil' : '/connexion?next=$path';
      }
      if ((path == '/statuts/nouveau' || path == '/profil/completer') &&
          !auth.isLoggedIn) {
        return '/connexion?next=$path';
      }
      if (path == '/connexion/code' &&
          auth.pendingPhone == null &&
          !auth.isLoggedIn) {
        return '/connexion';
      }
      return null;
    },
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
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: ListingDetailScreen(listingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/courtier/:id',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: BrokerDetailScreen(brokerId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/demande/nouvelle',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: InquiryFormScreen(
            listingId: state.uri.queryParameters['listingId'],
          ),
        ),
      ),
      GoRoute(
        path: '/connexion',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: PhoneAuthScreen(nextPath: state.uri.queryParameters['next']),
        ),
      ),
      GoRoute(
        path: '/connexion/code',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: WhatsAppCodeScreen(
            nextPath: state.uri.queryParameters['next'],
          ),
        ),
      ),
      GoRoute(
        path: '/annonce/nouvelle',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const CreateListingScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/annonces',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const AdminListingsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/annonceurs',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const AdminAdvertisersScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/stories',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const AdminStoriesScreen(),
        ),
      ),
      GoRoute(
        path: '/statuts/nouveau',
        pageBuilder: (context, state) =>
            fadeSlidePage(key: state.pageKey, child: const CreateStoryScreen()),
      ),
      GoRoute(
        path: '/statuts/:phone',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: StoryViewerScreen(authorPhone: state.pathParameters['phone']!),
        ),
      ),
      GoRoute(
        path: '/annonceur/:phone',
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: AdvertiserProfileScreen(phone: state.pathParameters['phone']!),
        ),
      ),
      GoRoute(
        path: '/profil/completer',
        pageBuilder: (context, state) =>
            fadeSlidePage(key: state.pageKey, child: const EditProfileScreen()),
      ),
    ],
  );
}
