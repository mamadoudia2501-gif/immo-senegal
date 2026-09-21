import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/ids.dart';
import '../../core/utils/phone.dart';
import '../mappers/supabase_mappers.dart';
import '../models/listing.dart';
import '../repositories/listing_repository.dart';
import 'supabase_schema.dart';

class SupabaseListingRepository extends ListingRepository {
  SupabaseListingRepository(this._client) : super.remote();

  final SupabaseClient _client;
  final List<Listing> _cache = [];

  String? get _uid => _client.auth.currentUser?.id;

  @override
  List<Listing> get userListings => [
    for (final listing in _cache)
      if (!listing.isDeleted) listing,
  ];

  /// Catalogue distant uniquement (pas de `sampleListings` mélangés).
  @override
  List<Listing> all({bool includeInactive = false}) {
    if (includeInactive) {
      return [
        for (final listing in _cache)
          if (!listing.isDeleted) listing,
      ];
    }
    return [
      for (final listing in _cache)
        if (listing.isPublic) listing,
    ];
  }

  @override
  Listing? byId(String id) {
    for (final listing in _cache) {
      if (listing.id == id && !listing.isDeleted) return listing;
    }
    return null;
  }

  @override
  List<Listing> byPublisher(String phone, {bool publicOnly = false}) {
    final local = senegalLocalDigits(phone);
    return [
      for (final listing in _cache)
        if (!listing.isDeleted &&
            listing.publisherPhone != null &&
            senegalLocalDigits(listing.publisherPhone!) == local &&
            (!publicOnly || listing.isPublic))
          listing,
    ];
  }

  @override
  Future<void> load() async {
    final byId = <String, Listing>{};

    void absorb(dynamic rows) {
      if (rows is! List) return;
      for (final row in rows) {
        if (row is! Map) continue;
        final listing = listingFromRow(Map<String, dynamic>.from(row));
        byId[listing.id] = listing;
      }
    }

    final publicRows = await _client
        .from(SupabaseSchema.listings)
        .select()
        .eq('status', SupabaseSchema.listingStatusActive);
    absorb(publicRows);

    final ownerId = _uid;
    if (ownerId != null) {
      final ownerRows = await _client
          .from(SupabaseSchema.listings)
          .select()
          .eq('owner_id', ownerId);
      absorb(ownerRows);
    }

    _cache
      ..clear()
      ..addAll(byId.values);
    loaded = true;
    notifyListeners();
  }

  @override
  Future<Listing> add(Listing listing) async {
    final ownerId = _uid;
    if (ownerId == null) return listing;
    final payload = listingToRow(
      listing,
      ownerId: ownerId,
      includeId: looksLikeUuid(listing.id),
    );
    final inserted = await _insertListing(payload);
    final created = listingFromRow(inserted);
    await load();
    return byId(created.id) ?? created;
  }

  Future<Map<String, dynamic>> _insertListing(
    Map<String, dynamic> payload,
  ) async {
    try {
      return Map<String, dynamic>.from(
        await _client
            .from(SupabaseSchema.listings)
            .insert(payload)
            .select()
            .single(),
      );
    } on PostgrestException {
      final core = Map<String, dynamic>.from(payload)
        ..remove('images')
        ..remove('placeholder_hue')
        ..remove('was_paid')
        ..remove('featured')
        ..remove('villa_style')
        ..remove('broker_id');
      return Map<String, dynamic>.from(
        await _client
            .from(SupabaseSchema.listings)
            .insert(core)
            .select()
            .single(),
      );
    }
  }

  @override
  Future<void> setActive({required String id, required bool isActive}) async {
    await _client
        .from(SupabaseSchema.listings)
        .update({'is_active': isActive})
        .eq('id', id);
    await load();
  }

  @override
  Future<bool> setLifecycle({
    required String id,
    required ListingLifecycle lifecycle,
  }) async {
    final current = byId(id);
    if (current == null || current.isDeleted) return false;
    if (!lifecycle.allowedFor(current.type)) return false;
    await _client
        .from(SupabaseSchema.listings)
        .update({'status': listingStatusToSql(lifecycle)})
        .eq('id', id);
    await load();
    return true;
  }
}
