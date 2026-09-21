import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/phone.dart';
import '../mappers/supabase_mappers.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import 'supabase_schema.dart';

/// Auth téléphone (OTP SMS) si le provider Phone est actif.
/// Sinon e-mail de secours `{8chiffres}@immo-senegal.test` + téléphone écrit
/// sur `profiles` après verification.
class SupabaseAuthRepository extends AuthRepository {
  SupabaseAuthRepository(this._client) : super.remote();

  final SupabaseClient _client;
  final Map<String, AppUser> _cache = {};
  var _otpEmailFallback = false;

  @override
  bool get isRemote => true;

  @override
  bool get pendingUsesEmailFallback => _otpEmailFallback;

  String get _fallbackEmail {
    final phone = pendingPhone;
    if (phone == null) return '';
    return '${senegalLocalDigits(phone)}@immo-senegal.test';
  }

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
    final rows = await _client
        .from(SupabaseSchema.profiles)
        .select()
        .neq('role', 'admin');
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
    _otpEmailFallback = false;
    final meta = <String, dynamic>{
      if (pendingName != null) 'display_name': pendingName,
      'phone': pendingPhone,
    };
    final e164 = pendingPhone!.replaceAll(' ', '');
    try {
      await _client.auth.signInWithOtp(phone: e164, data: meta);
    } catch (_) {
      _otpEmailFallback = true;
      await _client.auth.signInWithOtp(
        email: _fallbackEmail,
        shouldCreateUser: true,
        data: meta,
      );
    }
    notifyListeners();
  }

  @override
  Future<bool> verifyDemoCode(String code) async {
    final phone = pendingPhone;
    if (phone == null) return false;
    final token = code.replaceAll(RegExp(r'\D'), '');
    try {
      if (_otpEmailFallback) {
        await _client.auth.verifyOTP(
          email: _fallbackEmail,
          token: token,
          type: OtpType.email,
        );
      } else {
        try {
          await _client.auth.verifyOTP(
            phone: phone.replaceAll(' ', ''),
            token: token,
            type: OtpType.sms,
          );
        } catch (_) {
          await _client.auth.verifyOTP(
            email: _fallbackEmail,
            token: token,
            type: OtpType.email,
          );
        }
      }
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return false;
      await _syncPhoneOnProfile(uid);
      currentUser = await _fetchProfile(uid);
      pendingPhone = null;
      pendingName = null;
      _otpEmailFallback = false;
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
          .from(SupabaseSchema.profiles)
          .update({'published_count': currentUser!.publishedCount + 1})
          .eq('id', uid);
      await load();
      return ListingSlot.adminUnlimited;
    }
    if (currentUser!.freeListingsRemaining > 0) {
      await _client
          .from(SupabaseSchema.profiles)
          .update({
            'free_listings_remaining': currentUser!.freeListingsRemaining - 1,
            'published_count': currentUser!.publishedCount + 1,
          })
          .eq('id', uid);
      await load();
      return ListingSlot.free;
    }
    await _client
        .from(SupabaseSchema.profiles)
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
    final payload = <String, dynamic>{};
    if (displayName != null) payload['display_name'] = displayName;
    if (whatsapp != null) payload['whatsapp'] = whatsapp;
    if (otherContact != null) payload['other_contact'] = otherContact;
    if (address != null) payload['address'] = address;
    if (city != null) payload['city'] = city;
    if (payload.isEmpty) return;
    await _client.from(SupabaseSchema.profiles).update(payload).eq('id', uid);
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
    try {
      await _client
          .from(SupabaseSchema.profiles)
          .update({'story_subscription_until': ends.toIso8601String()})
          .eq('id', uid);
    } catch (_) {
      await _client.from(SupabaseSchema.storySubscriptions).upsert({
        'profile_id': uid,
        'starts_at': start.toIso8601String(),
        'ends_at': ends.toIso8601String(),
        'amount_fcfa': AppConstants.storySubscriptionFcfa,
      });
    }
    await load();
    return true;
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    currentUser = null;
    pendingPhone = null;
    pendingName = null;
    _otpEmailFallback = false;
    notifyListeners();
  }

  Future<void> _syncPhoneOnProfile(String uid) async {
    final payload = <String, dynamic>{
      if (pendingPhone != null) 'phone': pendingPhone,
      if (pendingName != null) 'display_name': pendingName,
    };
    if (payload.isEmpty) return;
    await _client.from(SupabaseSchema.profiles).update(payload).eq('id', uid);
  }

  Future<AppUser?> _fetchProfile(String uid) async {
    final row = await _client
        .from(SupabaseSchema.profiles)
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    DateTime? until;
    try {
      final sub = await _client
          .from(SupabaseSchema.storySubscriptions)
          .select()
          .eq('profile_id', uid)
          .maybeSingle();
      if (sub != null && sub['ends_at'] is String) {
        until = DateTime.tryParse(sub['ends_at'] as String);
      }
    } catch (_) {
      until = null;
    }
    return profileFromRow(
      Map<String, dynamic>.from(row),
      subscriptionUntil: until,
    );
  }
}
