import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mock/sample_data.dart';
import '../models/listing.dart';

class ListingRepository extends ChangeNotifier {
  ListingRepository({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _storageKey = 'immo_senegal_user_listings';

  SharedPreferences? _preferences;
  final List<Listing> _userListings = [];
  bool loaded = false;

  List<Listing> get userListings => List.unmodifiable(_userListings);

  List<Listing> all({bool includeInactive = false}) {
    final extras = includeInactive
        ? _userListings
        : _userListings.where((listing) => listing.isActive);
    return [...extras, ...sampleListings];
  }

  List<Listing> featured() => all()
      .where((listing) => listing.featured && listing.isActive)
      .toList(growable: false);

  Listing? byId(String id) {
    for (final listing in all(includeInactive: true)) {
      if (listing.id == id) return listing;
    }
    return null;
  }

  List<Listing> byBroker(String brokerId) => all()
      .where((listing) => listing.brokerId == brokerId)
      .toList(growable: false);

  List<Listing> byPublisher(String phone) => _userListings
      .where((listing) => listing.publisherPhone == phone)
      .toList(growable: false);

  List<Listing> search({
    String query = '',
    String? city,
    ListingType? type,
    PropertyKind? kind,
    ApartmentLayout? apartmentLayout,
    VillaStyle? villaStyle,
    int? minFcfa,
    int? maxFcfa,
    bool recentOnly = false,
  }) {
    final needle = query.trim().toLowerCase();
    final cutoff = DateTime(2026, 8, 1);
    final results = all().where((listing) {
      if (city != null && listing.city != city) return false;
      if (type != null && listing.type != type) return false;
      if (kind != null) {
        if (kind == PropertyKind.appartement) {
          if (listing.kind != PropertyKind.appartement) return false;
        } else if (listing.kind != kind) {
          return false;
        }
      }
      if (apartmentLayout != null) {
        if (listing.apartmentLayout != apartmentLayout) return false;
      }
      if (villaStyle != null && listing.villaStyle != villaStyle) {
        return false;
      }
      if (minFcfa != null && listing.priceFcfa < minFcfa) return false;
      if (maxFcfa != null && listing.priceFcfa > maxFcfa) return false;
      if (recentOnly && listing.publishedAt.isBefore(cutoff)) return false;
      if (needle.isEmpty) return true;
      final haystack =
          '${listing.title} ${listing.city} ${listing.neighborhood} '
                  '${listing.kind.label} ${listing.layoutLabel ?? ''} '
                  '${listing.description}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList();
    if (recentOnly) {
      results.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    }
    return results;
  }

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _userListings
      ..clear()
      ..addAll(_decode(_preferences!.getString(_storageKey)));
    loaded = true;
    notifyListeners();
  }

  Future<Listing> add(Listing listing) async {
    _userListings.insert(0, listing);
    await _persist();
    notifyListeners();
    return listing;
  }

  Future<void> setActive({required String id, required bool isActive}) async {
    final index = _userListings.indexWhere((listing) => listing.id == id);
    if (index < 0) return;
    _userListings[index] = _userListings[index].copyWith(isActive: isActive);
    await _persist();
    notifyListeners();
  }

  List<Listing> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map) Listing.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _userListings.map((listing) => listing.toJson()).toList(),
    );
    await _preferences!.setString(_storageKey, payload);
  }
}
