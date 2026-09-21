import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/app.dart';
import 'package:immo_senegal/core/constants/app_constants.dart';
import 'package:immo_senegal/data/repositories/auth_repository.dart';
import 'package:immo_senegal/data/repositories/broker_repository.dart';
import 'package:immo_senegal/data/repositories/conversation_repository.dart';
import 'package:immo_senegal/data/repositories/inquiry_repository.dart';
import 'package:immo_senegal/data/repositories/listing_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    (
      InquiryRepository,
      ConversationRepository,
      ListingRepository,
      AuthRepository,
    )
  >
  repos() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final inquiries = InquiryRepository(preferences: prefs);
    final conversations = ConversationRepository(preferences: prefs);
    final listings = ListingRepository(preferences: prefs);
    final auth = AuthRepository(preferences: prefs);
    await Future.wait([
      inquiries.load(),
      conversations.load(),
      listings.load(),
      auth.load(),
    ]);
    return (inquiries, conversations, listings, auth);
  }

  test('une demande crée une conversation liée à l’annonce', () async {
    final bundle = await repos();
    final inquiries = bundle.$1;
    final conversations = bundle.$2;
    final listings = bundle.$3;
    const brokers = BrokerRepository();

    final inquiry = await inquiries.add(
      name: 'Awa Ndiaye',
      phone: '+221 77 123 45 67',
      message: 'Je souhaite visiter ce terrain à Bargny.',
      listingId: 'l3',
    );
    final listing = listings.byId('l3');
    expect(listing, isNotNull);

    final conversation = conversations.startFromInquiry(
      inquiry: inquiry,
      listing: listing,
      advertiserPhone: ConversationRepository.ownerPhone(
        listing: listing,
        brokers: brokers,
      ),
    );

    expect(conversation.inquiryId, inquiry.id);
    expect(conversation.listingId, 'l3');
    expect(conversation.requesterPhone, '+221 77 123 45 67');
    expect(conversation.advertiserPhone, '+221 76 234 56 78');
    expect(conversation.messages, hasLength(1));
    expect(conversation.messages.single.body, contains('Bargny'));
    expect(conversations.byInquiry(inquiry.id)?.id, conversation.id);
    expect(
      conversations.startFromInquiry(inquiry: inquiry).id,
      conversation.id,
    );
  });

  test('messages visibles des deux côtés (demandeur et annonceur)', () async {
    final bundle = await repos();
    final inquiries = bundle.$1;
    final conversations = bundle.$2;
    final listings = bundle.$3;
    const brokers = BrokerRepository();
    const requester = '+221 77 123 45 67';
    const advertiser = '+221 76 234 56 78';

    final inquiry = await inquiries.add(
      name: 'Awa Ndiaye',
      phone: requester,
      message: 'Toujours disponible pour une visite ?',
      listingId: 'l3',
    );
    final conversation = conversations.startFromInquiry(
      inquiry: inquiry,
      listing: listings.byId('l3'),
      advertiserPhone: ConversationRepository.ownerPhone(
        listing: listings.byId('l3'),
        brokers: brokers,
      ),
    );

    expect(
      conversations.sendMessage(
        conversationId: conversation.id,
        authorPhone: requester,
        body: 'Je peux passer demain matin.',
      ),
      isNotNull,
    );
    expect(
      conversations.sendMessage(
        conversationId: conversation.id,
        authorPhone: advertiser,
        body: 'Oui, 10 h à Bargny conviennent.',
      ),
      isNotNull,
    );

    final asRequester = conversations.forParticipant(requester).single;
    final asAdvertiser = conversations.forParticipant(advertiser).single;
    expect(asRequester.id, asAdvertiser.id);
    expect(asRequester.messages, hasLength(3));
    expect(asAdvertiser.messages.map((message) => message.body).toList(), [
      'Toujours disponible pour une visite ?',
      'Je peux passer demain matin.',
      'Oui, 10 h à Bargny conviennent.',
    ]);
    expect(
      conversations.canWrite(conversation: asRequester, phone: requester),
      isTrue,
    );
    expect(
      conversations.canWrite(conversation: asAdvertiser, phone: advertiser),
      isTrue,
    );
    expect(
      conversations.canWrite(conversation: asRequester, phone: '770000001'),
      isFalse,
    );
  });

  testWidgets('demande puis chat in-app sans quitter l’application', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await initializeDateFormatting('fr_FR');
    final bundle = await repos();

    await tester.pumpWidget(
      ImmoApp(
        inquiryRepository: bundle.$1,
        conversationRepository: bundle.$2,
        listingRepository: bundle.$3,
        authRepository: bundle.$4,
        mockLoadDelay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Recherche'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-type-terrain')));
    await tester.pumpAndSettle();
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

    expect(find.text(AppConstants.whatsappDemoCode), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('auth-code')),
      AppConstants.whatsappDemoCode,
    );
    await tester.tap(find.byKey(const Key('auth-verify')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-input')), findsOneWidget);
    expect(find.textContaining('Bargny'), findsWidgets);
    expect(find.textContaining('Envoyé'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'Merci, je reste disponible.',
    );
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('Merci, je reste disponible.'), findsOneWidget);

    await tester.tap(find.byTooltip('Voir l’annonce'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('listing-continue-chat')), findsOneWidget);

    expect(bundle.$2.conversations, hasLength(1));
    expect(bundle.$2.conversations.single.messages, hasLength(2));
  });
}
