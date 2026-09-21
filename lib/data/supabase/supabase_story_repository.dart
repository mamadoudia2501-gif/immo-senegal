import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/phone.dart';
import '../mappers/supabase_mappers.dart';
import '../models/app_user.dart';
import '../models/story.dart';
import '../repositories/story_repository.dart';

class SupabaseStoryRepository extends StoryRepository {
  SupabaseStoryRepository(this._client) : super.remote();

  final SupabaseClient _client;
  final List<Story> _cache = [];

  List<Story> get _all => _cache;

  @override
  List<Story> publicFeed() {
    final clock = now();
    return _all.where((story) => story.isLive(clock)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  List<Story> pending() {
    return _cache.where((story) => story.status == StoryStatus.pending).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  List<Story> byAuthor(String phone, {bool publicOnly = false}) {
    final local = senegalLocalDigits(phone);
    final clock = now();
    return _all.where((story) {
      if (senegalLocalDigits(story.authorPhone) != local) return false;
      if (publicOnly) return story.isLive(clock);
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Story? byId(String id) {
    for (final story in _all) {
      if (story.id == id) return story;
    }
    return null;
  }

  @override
  Future<void> load() async {
    final rows = await _client
        .from('stories')
        .select()
        .order('created_at', ascending: false);
    _cache
      ..clear()
      ..addAll([
        for (final row in rows as List)
          if (row is Map) storyFromRow(Map<String, dynamic>.from(row)),
      ]);
    loaded = true;
    notifyListeners();
  }

  @override
  StorySubmitResult submit({
    required AppUser? user,
    required StoryMedia media,
    String caption = '',
  }) {
    if (user == null) return StorySubmitResult.needsAuth;
    if (user.isAdmin) return StorySubmitResult.notAdvertiser;
    if (!user.hasActiveStorySubscription(now())) {
      return StorySubmitResult.needsSubscription;
    }
    final createdAt = now();
    unawaited(
      (() async {
        await _client.from('stories').insert({
          'author_id': _client.auth.currentUser?.id,
          'author_phone': user.phone,
          'media_path': media.id,
          'media_kind': media.kind.name,
          'media_label': media.label,
          'media_hue': media.hue,
          'caption': caption.trim(),
          'status': 'pending',
          'created_at': createdAt.toIso8601String(),
          'expires_at': createdAt
              .add(const Duration(hours: AppConstants.storyTtlHours))
              .toIso8601String(),
        });
        await load();
      })(),
    );
    return StorySubmitResult.submitted;
  }

  @override
  Future<void> setStatus({
    required String id,
    required StoryStatus status,
  }) async {
    await _client
        .from('stories')
        .update({'status': status.name, 'reviewed_at': now().toIso8601String()})
        .eq('id', id);
    await load();
  }
}
