import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/app.dart';
import 'package:immo_senegal/data/models/listing.dart';
import 'package:immo_senegal/data/repositories/auth_repository.dart';
import 'package:immo_senegal/data/repositories/inquiry_repository.dart';
import 'package:immo_senegal/data/repositories/listing_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester, ListingRepository listings) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('fr_FR');
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthRepository(preferences: prefs);
  final inquiries = InquiryRepository(preferences: prefs);
  await auth.load();
  await inquiries.load();

  await tester.pumpWidget(
    ImmoApp(
      inquiryRepository: inquiries,
      authRepository: auth,
      listingRepository: listings,
      mockLoadDelay: Duration.zero,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Recherche'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ListingRepository repo() => ListingRepository();

  test('filtre location appartement F3', () {
    final results = repo().search(
      type: ListingType.location,
      kind: PropertyKind.appartement,
      apartmentLayout: ApartmentLayout.f3,
    );
    expect(results.map((listing) => listing.id), ['l1', 'l8', 'l30']);
    expect(
      results.every(
        (listing) =>
            listing.kind == PropertyKind.appartement && listing.rooms == 3,
      ),
      isTrue,
    );
  });

  test('filtre location villa avec piscine', () {
    final results = repo().search(
      type: ListingType.location,
      kind: PropertyKind.villa,
      villaStyle: VillaStyle.piscine,
    );
    expect(results.map((listing) => listing.id), ['l24']);
  });

  test('filtre loyer mensuel jusqu’à 200 000 FCFA', () {
    final results = repo().search(type: ListingType.location, maxFcfa: 200000);
    expect(results.every((listing) => listing.priceFcfa <= 200000), isTrue);
    expect(results.any((listing) => listing.id == 'l1'), isFalse);
    expect(
      results.map((listing) => listing.id),
      containsAll(['l8', 'l19', 'l30']),
    );
  });

  test('filtre vente villa basique sous 40 M', () {
    final results = repo().search(
      type: ListingType.vente,
      kind: PropertyKind.villa,
      villaStyle: VillaStyle.basique,
      maxFcfa: 40000000,
    );
    expect(results.map((listing) => listing.id), ['l28']);
  });

  testWidgets('Location : Appartement puis F2–F6, filtre F3', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final listings = ListingRepository(preferences: prefs);
    await listings.load();
    await _pumpApp(tester, listings);
    await _openSearch(tester);

    await tester.tap(find.byKey(const Key('filter-type-location')));
    await tester.pumpAndSettle();

    expect(find.text('Type de bien'), findsOneWidget);
    expect(find.byKey(const Key('filter-kind-appartement')), findsOneWidget);
    expect(find.byKey(const Key('filter-kind-villa')), findsOneWidget);
    expect(find.byKey(const Key('filter-layout-f3')), findsNothing);
    expect(find.byKey(const Key('filter-villa-piscine')), findsNothing);

    await tester.tap(find.byKey(const Key('filter-kind-appartement')));
    await tester.pumpAndSettle();

    expect(find.text('Typologie'), findsOneWidget);
    expect(find.byKey(const Key('filter-layout-f2')), findsOneWidget);
    expect(find.byKey(const Key('filter-layout-f3')), findsOneWidget);
    expect(find.byKey(const Key('filter-layout-f4')), findsOneWidget);
    expect(find.byKey(const Key('filter-layout-f5')), findsOneWidget);
    expect(find.byKey(const Key('filter-layout-f6')), findsOneWidget);
    expect(find.byKey(const Key('filter-villa-piscine')), findsNothing);

    await tester.tap(find.byKey(const Key('filter-layout-f3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('listing-card-l1')), findsOneWidget);
    expect(find.byKey(const Key('listing-card-l19')), findsNothing);
    expect(find.textContaining('locations'), findsWidgets);
  });

  testWidgets('Location : Villa puis types, filtre piscine', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final listings = ListingRepository(preferences: prefs);
    await listings.load();
    await _pumpApp(tester, listings);
    await _openSearch(tester);

    await tester.tap(find.byKey(const Key('filter-type-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-kind-villa')));
    await tester.pumpAndSettle();

    expect(find.text('Style de villa'), findsOneWidget);
    expect(find.byKey(const Key('filter-villa-basique')), findsOneWidget);
    expect(find.byKey(const Key('filter-villa-standing')), findsOneWidget);
    expect(find.byKey(const Key('filter-villa-duplex')), findsOneWidget);
    expect(find.byKey(const Key('filter-villa-piscine')), findsOneWidget);
    expect(find.byKey(const Key('filter-layout-f3')), findsNothing);

    await tester.tap(find.byKey(const Key('filter-villa-piscine')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('listing-card-l24')), findsOneWidget);
    expect(find.byKey(const Key('listing-card-l22')), findsNothing);
  });

  testWidgets('Location : preset loyer moins de 200 000 / mois', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final listings = ListingRepository(preferences: prefs);
    await listings.load();
    await _pumpApp(tester, listings);
    await _openSearch(tester);

    await tester.tap(find.byKey(const Key('filter-type-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-price')));
    await tester.pumpAndSettle();

    expect(find.text('Loyer mensuel (FCFA)'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('filter-price-preset-loc-under-200k')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('listing-card-l4')), findsOneWidget);
    expect(find.byKey(const Key('listing-card-l1')), findsNothing);
  });
}
