import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/phone.dart';
import '../models/app_user.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository({SharedPreferences? preferences}) : _preferences = preferences;

  AuthRepository.remote() : _preferences = null;

  static const _sessionKey = 'immo_senegal_session_phone';
  static const _usersKey = 'immo_senegal_users';

  SharedPreferences? _preferences;
  final Map<String, AppUser> _users = {};
  AppUser? currentUser;
  String? pendingPhone;
  String? pendingName;
  bool loaded = false;

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;
  bool get isPendingAdmin {
    final phone = pendingPhone;
    if (phone == null) return false;
    return senegalLocalDigits(phone) == AppConstants.adminPhoneLocal;
  }

  bool get canPublishWithoutPayment =>
      currentUser != null &&
      (currentUser!.isAdmin || currentUser!.freeListingsRemaining > 0);

  List<AppUser> get advertisers =>
      _users.values.where((user) => !user.isAdmin).toList(growable: false);

  AppUser? byPhone(String phone) => _users[senegalLocalDigits(phone)];

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _users
      ..clear()
      ..addAll(_decodeUsers(_preferences!.getString(_usersKey)));
    final sessionPhone = _preferences!.getString(_sessionKey);
    if (sessionPhone != null) {
      currentUser = _users[senegalLocalDigits(sessionPhone)];
    }
    loaded = true;
    notifyListeners();
  }

  /// Simule l’envoi d’un code WhatsApp (aucun SMS réel).
  Future<void> requestCode({required String phone, String? name}) async {
    pendingPhone = formatSenegalPhone(phone);
    pendingName = (name ?? '').trim().isEmpty ? null : name!.trim();
    notifyListeners();
  }

  Future<bool> verifyDemoCode(String code) async {
    if (pendingPhone == null) return false;
    final local = senegalLocalDigits(pendingPhone!);
    final expected = AppConstants.otpForLocalPhone(local);
    if (code.replaceAll(RegExp(r'\D'), '') != expected) {
      return false;
    }
    final existing = _users[local];
    final isAdmin = local == AppConstants.adminPhoneLocal;
    final user =
        existing ??
        AppUser(
          phone: pendingPhone!,
          displayName: pendingName ?? (isAdmin ? 'Admin Immo' : 'Annonceur'),
          role: isAdmin ? UserRole.admin : UserRole.advertiser,
          freeListingsRemaining: isAdmin ? 0 : AppConstants.freeListingQuota,
        );
    final named = pendingName == null
        ? user
        : user.copyWith(displayName: pendingName);
    _users[local] = named;
    currentUser = named;
    pendingPhone = null;
    pendingName = null;
    await _persist();
    notifyListeners();
    return true;
  }

  ListingSlot previewListingSlot() {
    final user = currentUser;
    if (user == null) return ListingSlot.notAuthenticated;
    if (user.isAdmin) return ListingSlot.adminUnlimited;
    if (user.freeListingsRemaining > 0) return ListingSlot.free;
    return ListingSlot.needsPayment;
  }

  /// Consomme un créneau : gratuit, payant (si [pay] est vrai) ou admin.
  Future<ListingSlot> reserveListingSlot({bool pay = false}) async {
    final user = currentUser;
    if (user == null) return ListingSlot.notAuthenticated;
    if (user.isAdmin) {
      currentUser = user.copyWith(publishedCount: user.publishedCount + 1);
      _users[senegalLocalDigits(user.phone)] = currentUser!;
      await _persist();
      notifyListeners();
      return ListingSlot.adminUnlimited;
    }
    if (user.freeListingsRemaining > 0) {
      currentUser = user.copyWith(
        freeListingsRemaining: user.freeListingsRemaining - 1,
        publishedCount: user.publishedCount + 1,
      );
      _users[senegalLocalDigits(user.phone)] = currentUser!;
      await _persist();
      notifyListeners();
      return ListingSlot.free;
    }
    if (!pay) return ListingSlot.needsPayment;
    currentUser = user.copyWith(
      publishedCount: user.publishedCount + 1,
      paidCount: user.paidCount + 1,
    );
    _users[senegalLocalDigits(user.phone)] = currentUser!;
    await _persist();
    notifyListeners();
    return ListingSlot.paid;
  }

  Future<void> updateProfile({
    String? displayName,
    String? whatsapp,
    String? otherContact,
    String? address,
    String? city,
  }) async {
    final user = currentUser;
    if (user == null || user.isAdmin) return;
    await _saveUser(
      user.copyWith(
        displayName: displayName,
        whatsapp: whatsapp,
        otherContact: otherContact,
        address: address,
        city: city,
      ),
    );
  }

  Future<bool> activateStorySubscription({DateTime? from}) async {
    final user = currentUser;
    if (user == null || user.isAdmin) return false;
    final clock = from ?? DateTime.now();
    final currentEnd = user.storySubscriptionUntil;
    final start = currentEnd != null && currentEnd.isAfter(clock)
        ? currentEnd
        : clock;
    await _saveUser(
      user.copyWith(
        storySubscriptionUntil: start.add(
          const Duration(days: AppConstants.storySubscriptionDays),
        ),
      ),
    );
    return true;
  }

  Future<void> _saveUser(AppUser user) async {
    currentUser = user;
    _users[senegalLocalDigits(user.phone)] = user;
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    pendingPhone = null;
    pendingName = null;
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.remove(_sessionKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _users.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _preferences!.setString(_usersKey, payload);
    if (currentUser != null) {
      await _preferences!.setString(_sessionKey, currentUser!.phone);
    } else {
      await _preferences!.remove(_sessionKey);
    }
  }

  Map<String, AppUser> _decodeUsers(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is Map)
            entry.key.toString(): AppUser.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
      };
    } catch (_) {
      return {};
    }
  }
}
