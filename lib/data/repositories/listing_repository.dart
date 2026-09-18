import '../mock/sample_data.dart';
import '../models/listing.dart';

class ListingRepository {
  const ListingRepository();

  List<Listing> all() => List.unmodifiable(sampleListings);

  List<Listing> featured() => sampleListings
      .where((listing) => listing.featured)
      .toList(growable: false);

  Listing? byId(String id) {
    for (final listing in sampleListings) {
      if (listing.id == id) return listing;
    }
    return null;
  }

  List<Listing> byBroker(String brokerId) => sampleListings
      .where((listing) => listing.brokerId == brokerId)
      .toList(growable: false);

  List<Listing> search({
    String query = '',
    String? city,
    ListingType? type,
    PriceRange priceRange = PriceRange.all,
  }) {
    final needle = query.trim().toLowerCase();
    return sampleListings
        .where((listing) {
          if (city != null && listing.city != city) return false;
          if (type != null && listing.type != type) return false;
          if (priceRange.minFcfa != null &&
              listing.priceFcfa < priceRange.minFcfa!) {
            return false;
          }
          if (priceRange.maxFcfa != null &&
              listing.priceFcfa > priceRange.maxFcfa!) {
            return false;
          }
          if (needle.isEmpty) return true;
          final haystack =
              '${listing.title} ${listing.city} ${listing.neighborhood} '
                      '${listing.kind.label} ${listing.description}'
                  .toLowerCase();
          return haystack.contains(needle);
        })
        .toList(growable: false);
  }
}
