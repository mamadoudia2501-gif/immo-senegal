import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/phone.dart';

enum UserRole {
  advertiser,
  admin;

  String get label => switch (this) {
    UserRole.advertiser => 'Annonceur',
    UserRole.admin => 'Administrateur',
  };
}

@immutable
class AppUser {
  const AppUser({
    required this.phone,
    required this.role,
    this.displayName,
    this.freeListingsRemaining = AppConstants.freeListingQuota,
    this.publishedCount = 0,
    this.paidCount = 0,
    this.whatsapp,
    this.otherContact,
    this.address,
    this.city,
    this.storySubscriptionUntil,
  });

  final String phone;
  final String? displayName;
  final UserRole role;
  final int freeListingsRemaining;
  final int publishedCount;
  final int paidCount;
  final String? whatsapp;
  final String? otherContact;
  final String? address;
  final String? city;
  final DateTime? storySubscriptionUntil;

  bool get isAdmin => role == UserRole.admin;

  bool get profileComplete =>
      (displayName ?? '').trim().length >= 2 &&
      (address ?? '').trim().length >= 4;

  bool hasActiveStorySubscription([DateTime? now]) {
    if (isAdmin) return false;
    final until = storySubscriptionUntil;
    if (until == null) return false;
    return until.isAfter(now ?? DateTime.now());
  }

  String get initials {
    final name = (displayName ?? '').trim();
    if (name.isEmpty) return isAdmin ? 'AD' : 'AN';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  AppUser copyWith({
    String? displayName,
    int? freeListingsRemaining,
    int? publishedCount,
    int? paidCount,
    String? whatsapp,
    String? otherContact,
    String? address,
    String? city,
    DateTime? storySubscriptionUntil,
    bool clearSubscription = false,
  }) {
    return AppUser(
      phone: phone,
      role: role,
      displayName: displayName ?? this.displayName,
      freeListingsRemaining:
          freeListingsRemaining ?? this.freeListingsRemaining,
      publishedCount: publishedCount ?? this.publishedCount,
      paidCount: paidCount ?? this.paidCount,
      whatsapp: whatsapp ?? this.whatsapp,
      otherContact: otherContact ?? this.otherContact,
      address: address ?? this.address,
      city: city ?? this.city,
      storySubscriptionUntil: clearSubscription
          ? null
          : (storySubscriptionUntil ?? this.storySubscriptionUntil),
    );
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'displayName': displayName,
    'role': role.name,
    'freeListingsRemaining': freeListingsRemaining,
    'publishedCount': publishedCount,
    'paidCount': paidCount,
    'whatsapp': whatsapp,
    'otherContact': otherContact,
    'address': address,
    'city': city,
    'storySubscriptionUntil': storySubscriptionUntil?.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      phone: json['phone'] as String,
      displayName: json['displayName'] as String?,
      role: UserRole.values.byName(json['role'] as String),
      freeListingsRemaining:
          json['freeListingsRemaining'] as int? ??
          AppConstants.freeListingQuota,
      publishedCount: json['publishedCount'] as int? ?? 0,
      paidCount: json['paidCount'] as int? ?? 0,
      whatsapp: json['whatsapp'] as String?,
      otherContact: json['otherContact'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      storySubscriptionUntil: json['storySubscriptionUntil'] is String
          ? DateTime.tryParse(json['storySubscriptionUntil'] as String)
          : null,
    );
  }
}

@immutable
class AdvertiserProfile {
  const AdvertiserProfile({
    required this.phone,
    required this.displayName,
    this.whatsapp,
    this.otherContact,
    this.address,
    this.city,
  });

  final String phone;
  final String displayName;
  final String? whatsapp;
  final String? otherContact;
  final String? address;
  final String? city;

  String get localPhone => senegalLocalDigits(phone);

  String get whatsappNumber =>
      (whatsapp ?? '').trim().isEmpty ? phone : whatsapp!.trim();

  String get initials {
    final parts = displayName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AN';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AdvertiserProfile.fromUser(AppUser user) {
    return AdvertiserProfile(
      phone: user.phone,
      displayName: (user.displayName ?? '').trim().isEmpty
          ? 'Annonceur'
          : user.displayName!.trim(),
      whatsapp: user.whatsapp,
      otherContact: user.otherContact,
      address: user.address,
      city: user.city,
    );
  }
}

enum ListingSlot { free, paid, needsPayment, adminUnlimited, notAuthenticated }
