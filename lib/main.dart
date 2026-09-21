import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/conversation_repository.dart';
import 'data/repositories/inquiry_repository.dart';
import 'data/repositories/listing_repository.dart';
import 'data/repositories/story_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final preferences = await SharedPreferences.getInstance();
  final inquiries = InquiryRepository(preferences: preferences);
  final auth = AuthRepository(preferences: preferences);
  final listings = ListingRepository(preferences: preferences);
  final stories = StoryRepository(preferences: preferences);
  final conversations = ConversationRepository(preferences: preferences);
  await Future.wait([
    inquiries.load(),
    auth.load(),
    listings.load(),
    stories.load(),
    conversations.load(),
  ]);
  runApp(
    ImmoApp(
      inquiryRepository: inquiries,
      authRepository: auth,
      listingRepository: listings,
      storyRepository: stories,
      conversationRepository: conversations,
    ),
  );
}
