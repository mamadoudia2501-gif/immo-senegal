import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/phone.dart';
import '../mock/sample_data.dart';
import '../models/app_user.dart';
import '../models/story.dart';

class StoryRepository extends ChangeNotifier {
  StoryRepository({SharedPreferences? preferences, DateTime Function()? clock})
    : _preferences = preferences,
      _clock = clock ?? DateTime.now;

  static const _storageKey = 'immo_senegal_stories';

  SharedPreferences? _preferences;
  final DateTime Function() _clock;
  final List<Story> _userStories = [];
  late final List<Story> _samples = buildSampleStories(_clock());
  bool loaded = false;

  DateTime now() => _clock();

  List<Story> get _all => [..._userStories, ..._samples];

  List<Story> publicFeed() {
    final clock = now();
    return _all.where((story) => story.isLive(clock)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Story> pending() {
    return _userStories
        .where((story) => story.status == StoryStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Story> byAuthor(String phone, {bool publicOnly = false}) {
    final local = senegalLocalDigits(phone);
    final clock = now();
    return _all.where((story) {
      if (senegalLocalDigits(story.authorPhone) != local) return false;
      if (publicOnly) return story.isLive(clock);
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<String> publicAuthorPhones() {
    final seen = <String>{};
    final phones = <String>[];
    for (final story in publicFeed()) {
      final local = senegalLocalDigits(story.authorPhone);
      if (seen.add(local)) phones.add(story.authorPhone);
    }
    return phones;
  }

  Story? byId(String id) {
    for (final story in _all) {
      if (story.id == id) return story;
    }
    return null;
  }

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
    _userStories.insert(
      0,
      Story(
        id: 'st${now().microsecondsSinceEpoch}',
        authorPhone: user.phone,
        media: media,
        caption: caption.trim(),
        createdAt: now(),
      ),
    );
    _persist();
    notifyListeners();
    return StorySubmitResult.submitted;
  }

  Future<void> setStatus({
    required String id,
    required StoryStatus status,
  }) async {
    final index = _userStories.indexWhere((story) => story.id == id);
    if (index < 0) return;
    _userStories[index] = _userStories[index].copyWith(
      status: status,
      reviewedAt: now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _userStories
      ..clear()
      ..addAll(_decode(_preferences!.getString(_storageKey)));
    loaded = true;
    notifyListeners();
  }

  List<Story> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map) Story.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(
      _storageKey,
      jsonEncode(_userStories.map((story) => story.toJson()).toList()),
    );
  }
}

AdvertiserProfile? resolveAdvertiserProfile({
  required String phone,
  required AppUser? registered,
}) {
  if (isReservedAdminPhone(phone)) return null;
  if (registered != null && !registered.isAdmin) {
    return AdvertiserProfile.fromUser(registered);
  }
  final local = senegalLocalDigits(phone);
  for (final profile in sampleAdvertisers) {
    if (senegalLocalDigits(profile.phone) == local) return profile;
  }
  return null;
}
