import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/core/config/app_config.dart';
import 'package:immo_senegal/core/utils/ids.dart';
import 'package:immo_senegal/data/backend/app_backend.dart';
import 'package:immo_senegal/data/mappers/supabase_mappers.dart';
import 'package:immo_senegal/data/models/app_user.dart';
import 'package:immo_senegal/data/models/listing.dart';
import 'package:immo_senegal/data/models/story.dart';
import 'package:immo_senegal/data/supabase/supabase_schema.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('l’URL test n’est pas une valeur par défaut compilée', () {
    expect(AppConfig.supabaseUrl, isNot(SupabaseSchema.testProjectUrl));
    expect(SupabaseSchema.messages, 'messages');
    expect(SupabaseSchema.listingImagesBucket, 'listing-images');
    expect(SupabaseSchema.storyMediaBucket, 'story-media');
    expect(SupabaseSchema.listingStatusActive, 'active');
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
    expect(listingToRow(listing, ownerId: 'owner-1')['images'], isA<List>());
  });

  test('photos depuis jsonb images (schéma live)', () {
    final listing = listingFromRow({
      'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      'title': 'Villa',
      'city': 'Saly',
      'neighborhood': 'Centre',
      'type': 'vente',
      'kind': 'villa',
      'price_fcfa': 85000000,
      'description': 'Vue mer',
      'status': 'active',
      'images': [
        {
          'storage_path': 'cover',
          'label': 'Façade',
          'hue': 12,
          'sort_order': 1,
        },
        {'id': 'salon', 'label': 'Salon', 'hue': 40, 'sort_order': 0},
      ],
    });
    expect(listing.lifecycle, ListingLifecycle.actif);
    expect(listing.isPublic, isTrue);
    expect(listing.photos, hasLength(2));
    expect(listing.photos.first.label, 'Salon');
    expect(listing.photos.first.id, 'salon');
  });

  test('messages : body/content/text + nid messages', () {
    final fromBody = chatMessageFromRow({
      'id': 'm1',
      'author_phone': '+221 77 111 22 33',
      'body': 'Bonjour',
      'created_at': '2026-09-21T10:00:00Z',
    });
    expect(fromBody.body, 'Bonjour');
    final fromContent = chatMessageFromRow({
      'id': 'm2',
      'sender_phone': '+221 77 111 22 33',
      'content': 'Disponible ?',
      'created_at': '2026-09-21T10:01:00Z',
    });
    expect(fromContent.body, 'Disponible ?');
    expect(fromContent.authorPhone, '+221 77 111 22 33');

    final nested = nestedMessagesFromConversationRow({
      'id': 'c1',
      'inquiry_id': 'i1',
      'requester_phone': '+221 77 111 22 33',
      'requester_name': 'Awa',
      'messages': [
        {'id': 'm2', 'body': 'Suite', 'created_at': '2026-09-21T10:02:00Z'},
        {'id': 'm1', 'text': 'Début', 'created_at': '2026-09-21T10:00:00Z'},
      ],
    });
    expect(nested.map((m) => m.body).toList(), ['Début', 'Suite']);
  });

  test('UUID v4 généré pour les PK distantes', () {
    final id = newUuid();
    expect(looksLikeUuid(id), isTrue);
    expect(looksLikeUuid('u123'), isFalse);
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
