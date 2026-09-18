import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/app.dart';
import 'package:immo_senegal/data/repositories/inquiry_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('fr_FR');
  final inquiries = InquiryRepository(
    preferences: await SharedPreferences.getInstance(),
  );
  await inquiries.load();
  await tester.pumpWidget(
    ImmoApp(inquiryRepository: inquiries, mockLoadDelay: Duration.zero),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('parcours accueil, recherche, fiche et demande', (tester) async {
    await _pumpApp(tester);

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
    await _pumpApp(tester);

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
}
