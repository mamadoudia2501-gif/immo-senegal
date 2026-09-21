import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/app.dart';
import 'package:immo_senegal/core/constants/app_constants.dart';
import 'package:immo_senegal/data/models/listing.dart';
import 'package:immo_senegal/data/repositories/auth_repository.dart';
import 'package:immo_senegal/data/repositories/inquiry_repository.dart';
import 'package:immo_senegal/data/repositories/listing_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Listing _listing({
  required String id,
  ListingType type = ListingType.location,
  String phone = '+221 77 111 22 33',
  bool featured = true,
}) {
  return Listing(
    id: id,
    title: 'F3 Almadies $id',
    city: 'Dakar',
    neighborhood: 'Almadies',
    type: type,
    kind: type == ListingType.terrain
        ? PropertyKind.terrain
        : PropertyKind.appartement,
    priceFcfa: 280000,
    description: 'Annonce de test pour le cycle de vie loué / vendu.',
    placeholderHue: 48,
    publisherPhone: phone,
    rooms: type == ListingType.terrain ? null : 3,
    featured: featured,
    listedAt: DateTime.utc(2026, 9, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ListingRepository, AuthRepository)> repos() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final listings = ListingRepository(preferences: prefs);
    final auth = AuthRepository(preferences: prefs);
    await listings.load();
    await auth.load();
    return (listings, auth);
  }

  test('marquer loué retire l’annonce du feed public', () async {
    final pair = await repos();
    final listings = pair.$1;
    await listings.add(_listing(id: 'u-rent'));

    expect(listings.all().any((listing) => listing.id == 'u-rent'), isTrue);
    expect(
      listings.featured().any((listing) => listing.id == 'u-rent'),
      isTrue,
    );
    expect(
      listings
          .search(type: ListingType.location)
          .any((listing) => listing.id == 'u-rent'),
      isTrue,
    );

    expect(
      await listings.setLifecycle(
        id: 'u-rent',
        lifecycle: ListingLifecycle.loue,
      ),
      isTrue,
    );

    expect(listings.all().any((listing) => listing.id == 'u-rent'), isFalse);
    expect(
      listings.featured().any((listing) => listing.id == 'u-rent'),
      isFalse,
    );
    expect(
      listings
          .search(query: 'Almadies')
          .any((listing) => listing.id == 'u-rent'),
      isFalse,
    );
    expect(listings.byId('u-rent')?.lifecycle, ListingLifecycle.loue);
    expect(
      listings.byPublisher('+221 77 111 22 33').single.ownerStatusLabel,
      'Loué',
    );
    expect(
      listings.byPublisher('+221 77 111 22 33', publicOnly: true),
      isEmpty,
    );
  });

  test('supprimer retire définitivement l’annonce', () async {
    final pair = await repos();
    final listings = pair.$1;
    await listings.add(
      _listing(id: 'u-del', type: ListingType.vente, featured: false),
    );

    expect(
      await listings.setLifecycle(
        id: 'u-del',
        lifecycle: ListingLifecycle.vendu,
      ),
      isTrue,
    );
    expect(listings.byId('u-del')?.isClosed, isTrue);

    expect(
      await listings.setLifecycle(
        id: 'u-del',
        lifecycle: ListingLifecycle.supprimee,
      ),
      isTrue,
    );
    expect(listings.byId('u-del'), isNull);
    expect(
      listings.userListings.any((listing) => listing.id == 'u-del'),
      isFalse,
    );
    expect(
      listings
          .byPublisher('+221 77 111 22 33')
          .any((listing) => listing.id == 'u-del'),
      isFalse,
    );
    expect(
      listings.search(type: ListingType.vente).any((l) => l.id == 'u-del'),
      isFalse,
    );
  });

  test('on ne peut pas marquer loué une vente', () async {
    final pair = await repos();
    final listings = pair.$1;
    await listings.add(_listing(id: 'u-sale', type: ListingType.vente));
    expect(
      await listings.setLifecycle(
        id: 'u-sale',
        lifecycle: ListingLifecycle.loue,
      ),
      isFalse,
    );
    expect(listings.byId('u-sale')?.isPublic, isTrue);
  });

  testWidgets('annonceur marque Loué : plus visible dans le fil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('fr_FR');
    final prefs = await SharedPreferences.getInstance();
    final listings = ListingRepository(preferences: prefs);
    final auth = AuthRepository(preferences: prefs);
    final inquiries = InquiryRepository(preferences: prefs);
    await Future.wait([listings.load(), auth.load(), inquiries.load()]);
    await auth.requestCode(phone: '771112233', name: 'Awa');
    await auth.verifyDemoCode(AppConstants.whatsappDemoCode);
    await listings.add(
      _listing(
        id: 'u-rent-ui',
        phone: auth.currentUser!.phone,
        featured: false,
      ),
    );

    await tester.pumpWidget(
      ImmoApp(
        inquiryRepository: inquiries,
        authRepository: auth,
        listingRepository: listings,
        mockLoadDelay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('my-listing-u-rent-ui')),
      240,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('listing-manage-u-rent-ui')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer Loué'));
    await tester.pumpAndSettle();

    expect(find.textContaining('marquée comme louée'), findsOneWidget);
    expect(listings.byId('u-rent-ui')?.lifecycle, ListingLifecycle.loue);
    expect(find.text('Loué'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Recherche'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('listing-card-u-rent-ui')), findsNothing);
    expect(find.textContaining('F3 Almadies u-rent-ui'), findsNothing);
  });
}
