import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/app.dart';
import 'package:immo_senegal/core/constants/app_constants.dart';
import 'package:immo_senegal/data/repositories/auth_repository.dart';
import 'package:immo_senegal/data/repositories/inquiry_repository.dart';
import 'package:immo_senegal/data/repositories/listing_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required AuthRepository auth,
  required ListingRepository listings,
  required InquiryRepository inquiries,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

Future<(AuthRepository, ListingRepository, InquiryRepository)> _repos() async {
  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('fr_FR');
  final prefs = await SharedPreferences.getInstance();
  final inquiries = InquiryRepository(preferences: prefs);
  final auth = AuthRepository(preferences: prefs);
  final listings = ListingRepository(preferences: prefs);
  await inquiries.load();
  await auth.load();
  await listings.load();
  return (auth, listings, inquiries);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('parcours accueil, recherche, fiche et demande', (tester) async {
    final repos = await _repos();
    await _pumpApp(
      tester,
      auth: repos.$1,
      listings: repos.$2,
      inquiries: repos.$3,
    );

    expect(find.text('Immo Sénégal'), findsWidgets);
    expect(find.text('Accueil'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Recherche'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('bien'), findsWidgets);

    await tester.tap(find.byKey(const Key('filter-type-terrain')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Terrain'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('listing-card-l3')),
      280,
      scrollable: find.descendant(
        of: find.byKey(const Key('search-results')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('listing-card-l3')));
    await tester.pumpAndSettle();
    expect(find.text('Faire une demande'), findsOneWidget);
    expect(find.textContaining('Rufisque'), findsWidgets);

    await tester.tap(find.byKey(const Key('listing-inquiry-cta')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('inquiry-name')), 'Awa Ndiaye');
    await tester.enterText(find.byKey(const Key('inquiry-phone')), '771234567');
    await tester.enterText(
      find.byKey(const Key('inquiry-message')),
      'Je souhaite visiter ce terrain à Bargny.',
    );
    await tester.tap(find.byKey(const Key('inquiry-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Demandes'), findsWidgets);
    expect(find.text('Awa Ndiaye'), findsOneWidget);
    expect(find.textContaining('Bargny'), findsWidgets);
  });

  testWidgets('annuaire des courtiers', (tester) async {
    final repos = await _repos();
    await _pumpApp(
      tester,
      auth: repos.$1,
      listings: repos.$2,
      inquiries: repos.$3,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Courtiers'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aminata Diop'), findsOneWidget);

    await tester.tap(find.byKey(const Key('broker-card-b1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Almadies Habitat'), findsWidgets);
    expect(find.byKey(const Key('broker-call-cta')), findsOneWidget);
  });

  testWidgets('visiteur publie via auth WhatsApp mock', (tester) async {
    final repos = await _repos();
    await _pumpApp(
      tester,
      auth: repos.$1,
      listings: repos.$2,
      inquiries: repos.$3,
    );

    await tester.tap(find.byKey(const Key('publish-cta')));
    await tester.pumpAndSettle();
    expect(find.textContaining('WhatsApp'), findsWidgets);

    await tester.enterText(find.byKey(const Key('auth-phone')), '771234567');
    await tester.tap(find.byKey(const Key('auth-continue')));
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.whatsappDemoCode), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('auth-code')),
      AppConstants.whatsappDemoCode,
    );
    await tester.tap(find.byKey(const Key('auth-verify')));
    await tester.pumpAndSettle();

    expect(find.textContaining('annonces gratuites'), findsWidgets);
    expect(
      find.textContaining('${AppConstants.freeListingQuota}'),
      findsWidgets,
    );
  });

  testWidgets('OTP admin jamais affiché, code 12345693 accepté', (
    tester,
  ) async {
    final repos = await _repos();
    await _pumpApp(
      tester,
      auth: repos.$1,
      listings: repos.$2,
      inquiries: repos.$3,
    );

    await tester.tap(find.byKey(const Key('publish-cta')));
    await tester.pumpAndSettle();

    expect(find.text('Comptes de démo'), findsNothing);
    expect(find.byKey(const Key('fill-admin-phone')), findsNothing);
    expect(find.text(AppConstants.whatsappAdminCode), findsNothing);
    expect(find.textContaining('77 000 00 00'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('auth-phone')),
      AppConstants.adminPhoneLocal,
    );
    await tester.tap(find.byKey(const Key('auth-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('whatsapp-admin-code-hidden')), findsOneWidget);
    expect(find.byKey(const Key('whatsapp-demo-code')), findsNothing);
    expect(find.text(AppConstants.whatsappAdminCode), findsNothing);
    expect(find.text(AppConstants.whatsappDemoCode), findsNothing);
    expect(find.textContaining('77 000 00 00'), findsNothing);
    expect(find.text('+221 77 000 00 00'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('auth-code')),
      AppConstants.whatsappAdminCode,
    );
    await tester.tap(find.byKey(const Key('auth-verify')));
    await tester.pumpAndSettle();

    expect(find.text('Compte administrateur'), findsWidgets);
    expect(find.text(AppConstants.whatsappAdminCode), findsNothing);
    expect(find.textContaining('77 000 00 00'), findsNothing);
  });

  testWidgets('publication : 1 à 4 photos mock', (tester) async {
    final repos = await _repos();
    await _pumpApp(
      tester,
      auth: repos.$1,
      listings: repos.$2,
      inquiries: repos.$3,
    );

    await tester.tap(find.byKey(const Key('publish-cta')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth-phone')), '771234567');
    await tester.tap(find.byKey(const Key('auth-continue')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('auth-code')),
      AppConstants.whatsappDemoCode,
    );
    await tester.tap(find.byKey(const Key('auth-verify')));
    await tester.pumpAndSettle();

    expect(find.text('0/4'), findsOneWidget);
    expect(find.byKey(const Key('create-add-photo')), findsOneWidget);

    Future<void> addPhoto(String id) async {
      await tester.tap(find.byKey(const Key('create-add-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('create-photo-option-$id')));
      await tester.pumpAndSettle();
    }

    await addPhoto('facade');
    expect(find.text('1/4'), findsOneWidget);
    await addPhoto('salon');
    await addPhoto('chambre');
    await addPhoto('cuisine');
    expect(find.text('4/4'), findsOneWidget);
    expect(find.byKey(const Key('create-add-photo')), findsNothing);

    await tester.tap(find.byTooltip('Supprimer').first);
    await tester.pumpAndSettle();
    expect(find.text('3/4'), findsOneWidget);
    expect(find.byKey(const Key('create-add-photo')), findsOneWidget);
  });
}
