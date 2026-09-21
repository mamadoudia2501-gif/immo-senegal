import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

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
  });

  final String phone;
  final String? displayName;
  final UserRole role;
  final int freeListingsRemaining;
  final int publishedCount;
  final int paidCount;

  bool get isAdmin => role == UserRole.admin;

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
  }) {
    return AppUser(
      phone: phone,
      role: role,
      displayName: displayName ?? this.displayName,
      freeListingsRemaining:
          freeListingsRemaining ?? this.freeListingsRemaining,
      publishedCount: publishedCount ?? this.publishedCount,
      paidCount: paidCount ?? this.paidCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'displayName': displayName,
    'role': role.name,
    'freeListingsRemaining': freeListingsRemaining,
    'publishedCount': publishedCount,
    'paidCount': paidCount,
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
    );
  }
}

enum ListingSlot { free, paid, needsPayment, adminUnlimited, notAuthenticated }
