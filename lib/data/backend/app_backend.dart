import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../repositories/auth_repository.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/inquiry_repository.dart';
import '../repositories/listing_repository.dart';
import '../repositories/story_repository.dart';
import '../supabase/supabase_auth_repository.dart';
import '../supabase/supabase_conversation_repository.dart';
import '../supabase/supabase_inquiry_repository.dart';
import '../supabase/supabase_listing_repository.dart';
import '../supabase/supabase_story_repository.dart';

class AppRepositories {
  const AppRepositories({
    required this.kind,
    required this.auth,
    required this.listings,
    required this.inquiries,
    required this.conversations,
    required this.stories,
  });

  final BackendKind kind;
  final AuthRepository auth;
  final ListingRepository listings;
  final InquiryRepository inquiries;
  final ConversationRepository conversations;
  final StoryRepository stories;
}

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
}

/// Mock local par défaut. Supabase si `SUPABASE_URL` + `SUPABASE_ANON_KEY`.
Future<AppRepositories> openAppRepositories({
  required SharedPreferences preferences,
}) async {
  if (!AppConfig.useSupabase) {
    return AppRepositories(
      kind: BackendKind.local,
      auth: AuthRepository(preferences: preferences),
      listings: ListingRepository(preferences: preferences),
      inquiries: InquiryRepository(preferences: preferences),
      conversations: ConversationRepository(preferences: preferences),
      stories: StoryRepository(preferences: preferences),
    );
  }
  await initializeSupabase();
  final client = Supabase.instance.client;
  return AppRepositories(
    kind: BackendKind.supabase,
    auth: SupabaseAuthRepository(client),
    listings: SupabaseListingRepository(client),
    inquiries: SupabaseInquiryRepository(client),
    conversations: SupabaseConversationRepository(client),
    stories: SupabaseStoryRepository(client),
  );
}
