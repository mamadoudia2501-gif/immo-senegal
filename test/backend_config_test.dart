import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/core/config/app_config.dart';
import 'package:immo_senegal/data/mappers/supabase_mappers.dart';
import 'package:immo_senegal/data/models/app_user.dart';
import 'package:immo_senegal/data/models/listing.dart';
import 'package:immo_senegal/data/models/story.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:immo_senegal/data/backend/app_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sans dart-define, le backend reste le mock local', () {
    expect(AppConfig.supabaseUrl, isEmpty);
    expect(AppConfig.supabaseAnonKey, isEmpty);
    expect(AppConfig.isSupabaseConfigured, isFalse);
    expect(AppConfig.useSupabase, isFalse);
    expect(AppConfig.kind, BackendKind.local);
    expect(AppConfig.backendLabel, contains('local'));
  });

  test('factory ouvre les dépôts mock sans Supabase', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final opened = await openAppRepositories(preferences: prefs);
    expect(opened.kind, BackendKind.local);
    await opened.listings.load();
    expect(opened.listings.all(), isNotEmpty);
  });

  test('mapping SQL status listings (active ↔ actif)', () {
    expect(listingStatusToSql(ListingLifecycle.actif), 'active');
    expect(listingStatusFromSql('active'), ListingLifecycle.actif);
    expect(listingStatusFromSql('loue'), ListingLifecycle.loue);
    expect(listingStatusFromSql('vendu'), ListingLifecycle.vendu);
    expect(listingStatusFromSql('supprimee'), ListingLifecycle.supprimee);
  });

  test('mapping profil et annonce depuis une ligne Supabase', () {
    final user = profileFromRow({
      'phone': '+221 77 111 22 33',
      'display_name': 'Awa',
      'role': 'advertiser',
      'free_listings_remaining': 3,
      'published_count': 1,
      'paid_count': 0,
    });
    expect(user.role, UserRole.advertiser);
    expect(user.displayName, 'Awa');
    expect(userRoleFromSql('visitor'), UserRole.visitor);
    expect(userRoleFromSql('admin'), UserRole.admin);

    final listing = listingFromRow({
      'id': 'u1',
      'title': 'F3 Almadies',
      'city': 'Dakar',
      'neighborhood': 'Almadies',
      'type': 'location',
      'kind': 'appartement',
      'price_fcfa': 280000,
      'description': 'Test',
      'placeholder_hue': 40,
      'featured': false,
      'is_active': true,
      'status': 'loue',
      'publisher_phone': '+221 77 111 22 33',
      'listing_photos': [
        {
          'id': 'p1',
          'storage_path': 'facade',
          'label': 'Façade',
          'hue': 32,
          'sort_order': 0,
        },
      ],
    });
    expect(listing.lifecycle, ListingLifecycle.loue);
    expect(listing.isPublic, isFalse);
    expect(listing.photos, hasLength(1));
    expect(listingToRow(listing, ownerId: 'owner-1')['status'], 'loue');
  });

  test('mapping story pending → file de validation', () {
    final story = storyFromRow({
      'id': 'st1',
      'author_phone': '+221 77 111 22 33',
      'media_path': 'visite',
      'media_kind': 'image',
      'media_label': 'Visite',
      'media_hue': 100,
      'caption': 'Hello',
      'status': 'pending',
      'created_at': '2026-09-21T10:00:00Z',
    });
    expect(story.status, StoryStatus.pending);
    expect(story.isLive(DateTime.utc(2026, 9, 21, 11)), isFalse);
  });
}
