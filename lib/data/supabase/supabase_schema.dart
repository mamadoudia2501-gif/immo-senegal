/// Noms alignés sur le projet test `immo-senegal-test`
/// (ref `zwjsnlcnyqhrtmhdjphb`, région eu-west-3).
///
/// L’URL publique du projet peut figurer dans le README.
/// La clé anon **ne doit jamais** être une constante ici.
abstract final class SupabaseSchema {
  static const testProjectRef = 'zwjsnlcnyqhrtmhdjphb';
  static const testProjectUrl = 'https://zwjsnlcnyqhrtmhdjphb.supabase.co';
  static const testRegion = 'eu-west-3';

  static const profiles = 'profiles';
  static const listings = 'listings';
  static const inquiries = 'inquiries';
  static const conversations = 'conversations';
  static const messages = 'messages';
  static const stories = 'stories';
  static const storySubscriptions = 'story_subscriptions';

  static const listingImagesBucket = 'listing-images';
  static const storyMediaBucket = 'story-media';

  static const listingStatusActive = 'active';
}
