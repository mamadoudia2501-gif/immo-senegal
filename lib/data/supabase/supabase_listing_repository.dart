import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/phone.dart';
import '../mock/sample_data.dart';
import '../models/listing.dart';
import '../repositories/listing_repository.dart';
import '../mappers/supabase_mappers.dart';

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

  @override
  List<Listing> all({bool includeInactive = false}) {
    final extras = includeInactive
        ? userListings
        : _cache.where((listing) => listing.isPublic);
    return [...extras, ...sampleListings];
  }

  @override
  Listing? byId(String id) {
    for (final listing in _cache) {
      if (listing.id == id && !listing.isDeleted) return listing;
    }
    for (final listing in sampleListings) {
      if (listing.id == id) return listing;
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
    final rows = await _client
        .from('listings')
        .select('*, listing_photos(*)')
        .neq('status', 'supprimee');
    _cache
      ..clear()
      ..addAll([
        for (final row in rows as List)
          if (row is Map) listingFromRow(Map<String, dynamic>.from(row)),
      ]);
    loaded = true;
    notifyListeners();
  }

  @override
  Future<Listing> add(Listing listing) async {
    final ownerId = _uid;
    if (ownerId == null) return listing;
    await _client
        .from('listings')
        .insert(listingToRow(listing, ownerId: ownerId));
    var order = 0;
    for (final photo in listing.photos) {
      await _client.from('listing_photos').insert({
        'listing_id': listing.id,
        'storage_path': photo.id,
        'label': photo.label,
        'hue': photo.hue,
        'sort_order': order,
      });
      order += 1;
    }
    await load();
    return byId(listing.id) ?? listing;
  }

  @override
  Future<void> setActive({required String id, required bool isActive}) async {
    await _client.from('listings').update({'is_active': isActive}).eq('id', id);
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
        .from('listings')
        .update({'status': listingStatusToSql(lifecycle)})
        .eq('id', id);
    await load();
    return true;
  }
}
