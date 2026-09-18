import 'package:flutter/foundation.dart';

import '../../data/models/listing.dart';

class ListingFilterController extends ChangeNotifier {
  String query = '';
  String? city;
  ListingType? type;
  PriceRange priceRange = PriceRange.all;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      city != null ||
      type != null ||
      priceRange != PriceRange.all;

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCity(String? value) {
    city = value;
    notifyListeners();
  }

  void setType(ListingType? value) {
    type = value;
    notifyListeners();
  }

  void setPriceRange(PriceRange value) {
    priceRange = value;
    notifyListeners();
  }

  void apply({
    String? query,
    String? city,
    ListingType? type,
    PriceRange? priceRange,
  }) {
    if (query != null) this.query = query;
    this.city = city;
    this.type = type;
    this.priceRange = priceRange ?? PriceRange.all;
    notifyListeners();
  }

  void clear() {
    query = '';
    city = null;
    type = null;
    priceRange = PriceRange.all;
    notifyListeners();
  }
}
