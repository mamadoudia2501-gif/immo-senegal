import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/app.dart';
import 'package:immo_senegal/core/constants/app_constants.dart';
import 'package:immo_senegal/data/models/story.dart';
import 'package:immo_senegal/data/repositories/auth_repository.dart';
import 'package:immo_senegal/data/repositories/inquiry_repository.dart';
import 'package:immo_senegal/data/repositories/listing_repository.dart';
import 'package:immo_senegal/data/repositories/story_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(AuthRepository, StoryRepository)> repos() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthRepository(preferences: prefs);
    final stories = StoryRepository(preferences: prefs);
    await auth.load();
    await stories.load();
    return (auth, stories);
  }

  test('abonnement requis pour soumettre une story', () async {
    final pair = await repos();
    final auth = pair.$1;
    final stories = pair.$2;
    await auth.requestCode(phone: '771112233', name: 'Awa');
    expect(await auth.verifyDemoCode(AppConstants.whatsappDemoCode), isTrue);
    expect(auth.currentUser!.hasActiveStorySubscription(), isFalse);

    expect(
      stories.submit(
        user: auth.currentUser,
        media: StoryMedia.catalog.first,
        caption: 'Visite',
      ),
      StorySubmitResult.needsSubscription,
    );
    expect(stories.pending(), isEmpty);

    expect(await auth.activateStorySubscription(), isTrue);
    expect(auth.currentUser!.hasActiveStorySubscription(), isTrue);

    expect(
      stories.submit(
        user: auth.currentUser,
        media: StoryMedia.catalog.first,
        caption: 'Visite Almadies',
      ),
      StorySubmitResult.submitted,
    );
    expect(stories.pending(), hasLength(1));
    expect(
      stories.publicFeed().any((story) => story.caption == 'Visite Almadies'),
      isFalse,
    );
  });

  test('validation admin avant visibilité publique', () async {
    final pair = await repos();
    final auth = pair.$1;
    final stories = pair.$2;
    await auth.requestCode(phone: '771112233', name: 'Awa');
    await auth.verifyDemoCode(AppConstants.whatsappDemoCode);
    await auth.activateStorySubscription();
    stories.submit(
      user: auth.currentUser,
      media: StoryMedia.catalog[4],
      caption: 'Vidéo villa',
    );
    final id = stories.pending().single.id;
    expect(stories.publicFeed().any((story) => story.id == id), isFalse);

    await stories.setStatus(id: id, status: StoryStatus.approved);
    expect(stories.pending(), isEmpty);
    expect(stories.publicFeed().any((story) => story.id == id), isTrue);

    await stories.setStatus(id: id, status: StoryStatus.rejected);
    expect(stories.publicFeed().any((story) => story.id == id), isFalse);
  });

  test('profil annonceur éditable', () async {
    final pair = await repos();
    final auth = pair.$1;
    await auth.requestCode(phone: '771112233', name: 'Awa');
    await auth.verifyDemoCode(AppConstants.whatsappDemoCode);
    expect(auth.currentUser!.profileComplete, isFalse);

    await auth.updateProfile(
      displayName: 'Awa Ndiaye',
      whatsapp: '+221 77 111 22 33',
      otherContact: 'awa@immo.sn',
      address: 'Sacré-Cœur 3',
      city: 'Dakar',
    );
    expect(auth.currentUser!.profileComplete, isTrue);
    expect(auth.currentUser!.address, 'Sacré-Cœur 3');
    expect(auth.currentUser!.city, 'Dakar');
    expect(auth.currentUser!.whatsapp, '+221 77 111 22 33');
  });

  test('admin sans abonnement, stories sample visibles visiteur', () async {
    final pair = await repos();
    final auth = pair.$1;
    final stories = pair.$2;
    await auth.requestCode(phone: AppConstants.adminPhoneLocal);
    await auth.verifyDemoCode(AppConstants.whatsappAdminCode);
    expect(auth.currentUser!.hasActiveStorySubscription(), isFalse);
    expect(
      stories.submit(user: auth.currentUser, media: StoryMedia.catalog.first),
      StorySubmitResult.notAdvertiser,
    );
    expect(stories.publicFeed(), isNotEmpty);
  });

  testWidgets('accueil affiche les statuts validés', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('fr_FR');
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthRepository(preferences: prefs);
    final inquiries = InquiryRepository(preferences: prefs);
    final listings = ListingRepository(preferences: prefs);
    final stories = StoryRepository(preferences: prefs);
    await Future.wait([
      auth.load(),
      inquiries.load(),
      listings.load(),
      stories.load(),
    ]);

    await tester.pumpWidget(
      ImmoApp(
        inquiryRepository: inquiries,
        authRepository: auth,
        listingRepository: listings,
        storyRepository: stories,
        mockLoadDelay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stories-strip')), findsOneWidget);
    expect(find.byKey(const Key('story-author-771112233')), findsOneWidget);
    expect(find.text(AppConstants.whatsappAdminCode), findsNothing);
    expect(find.textContaining('77 000 00 00'), findsNothing);
  });
}
