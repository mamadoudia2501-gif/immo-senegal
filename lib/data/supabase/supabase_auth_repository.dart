import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/phone.dart';
import '../mappers/supabase_mappers.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository(this._client) : super.remote();

  final SupabaseClient _client;
  final Map<String, AppUser> _cache = {};

  @override
  AppUser? byPhone(String phone) => _cache[senegalLocalDigits(phone)];

  @override
  List<AppUser> get advertisers =>
      _cache.values.where((user) => !user.isAdmin).toList(growable: false);

  @override
  Future<void> load() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      currentUser = await _fetchProfile(session.user.id);
    }
    final rows = await _client.from('profiles').select().neq('role', 'admin');
    _cache
      ..clear()
      ..addAll({
        for (final row in rows as List)
          if (row is Map)
            senegalLocalDigits((row['phone'] as String?) ?? ''): profileFromRow(
              Map<String, dynamic>.from(row),
            ),
      });
    loaded = true;
    notifyListeners();
  }

  @override
  Future<void> requestCode({required String phone, String? name}) async {
    pendingPhone = formatSenegalPhone(phone);
    pendingName = (name ?? '').trim().isEmpty ? null : name!.trim();
    final e164 = pendingPhone!.replaceAll(' ', '');
    await _client.auth.signInWithOtp(
      phone: e164,
      data: {if (pendingName != null) 'display_name': pendingName},
    );
    notifyListeners();
  }

  @override
  Future<bool> verifyDemoCode(String code) async {
    final phone = pendingPhone;
    if (phone == null) return false;
    try {
      await _client.auth.verifyOTP(
        phone: phone.replaceAll(' ', ''),
        token: code.replaceAll(RegExp(r'\D'), ''),
        type: OtpType.sms,
      );
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return false;
      currentUser = await _fetchProfile(uid);
      pendingPhone = null;
      pendingName = null;
      notifyListeners();
      return currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ListingSlot> reserveListingSlot({bool pay = false}) async {
    final slot = previewListingSlot();
    if (slot == ListingSlot.notAuthenticated ||
        slot == ListingSlot.needsPayment && !pay) {
      return slot == ListingSlot.needsPayment ? ListingSlot.needsPayment : slot;
    }
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return ListingSlot.notAuthenticated;
    if (currentUser!.isAdmin) {
      await _client
          .from('profiles')
          .update({'published_count': currentUser!.publishedCount + 1})
          .eq('id', uid);
      await load();
      return ListingSlot.adminUnlimited;
    }
    if (currentUser!.freeListingsRemaining > 0) {
      await _client
          .from('profiles')
          .update({
            'free_listings_remaining': currentUser!.freeListingsRemaining - 1,
            'published_count': currentUser!.publishedCount + 1,
          })
          .eq('id', uid);
      await load();
      return ListingSlot.free;
    }
    await _client
        .from('profiles')
        .update({
          'published_count': currentUser!.publishedCount + 1,
          'paid_count': currentUser!.paidCount + 1,
        })
        .eq('id', uid);
    await load();
    return ListingSlot.paid;
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? whatsapp,
    String? otherContact,
    String? address,
    String? city,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || currentUser == null || currentUser!.isAdmin) return;
    await _client
        .from('profiles')
        .update({
          'display_name': ?displayName,
          'whatsapp': ?whatsapp,
          'other_contact': ?otherContact,
          'address': ?address,
          'city': ?city,
        })
        .eq('id', uid);
    await load();
  }

  @override
  Future<bool> activateStorySubscription({DateTime? from}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || currentUser == null || currentUser!.isAdmin) {
      return false;
    }
    final clock = from ?? DateTime.now();
    final currentEnd = currentUser!.storySubscriptionUntil;
    final start = currentEnd != null && currentEnd.isAfter(clock)
        ? currentEnd
        : clock;
    final ends = start.add(
      const Duration(days: AppConstants.storySubscriptionDays),
    );
    await _client.from('story_subscriptions').upsert({
      'profile_id': uid,
      'starts_at': start.toIso8601String(),
      'ends_at': ends.toIso8601String(),
      'amount_fcfa': AppConstants.storySubscriptionFcfa,
    });
    await load();
    return true;
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    currentUser = null;
    pendingPhone = null;
    pendingName = null;
    notifyListeners();
  }

  Future<AppUser?> _fetchProfile(String uid) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    DateTime? until;
    final sub = await _client
        .from('story_subscriptions')
        .select()
        .eq('profile_id', uid)
        .maybeSingle();
    if (sub != null && sub['ends_at'] is String) {
      until = DateTime.tryParse(sub['ends_at'] as String);
    }
    return profileFromRow(
      Map<String, dynamic>.from(row),
      subscriptionUntil: until,
    );
  }
}
