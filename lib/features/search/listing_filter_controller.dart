import 'package:flutter/foundation.dart';

import '../../data/models/listing.dart';

class ListingFilterController extends ChangeNotifier {
  String query = '';
  String? city;
  ListingType? type;
  PropertyKind? kind;
  ApartmentLayout? apartmentLayout;
  VillaStyle? villaStyle;
  int? minFcfa;
  int? maxFcfa;
  bool recentOnly = false;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      city != null ||
      type != null ||
      kind != null ||
      apartmentLayout != null ||
      villaStyle != null ||
      minFcfa != null ||
      maxFcfa != null ||
      recentOnly;

  bool get isHousing =>
      type == ListingType.location || type == ListingType.vente;

  bool get showApartmentLayouts =>
      isHousing && kind == PropertyKind.appartement;

  bool get showVillaStyles => isHousing && kind == PropertyKind.villa;

  String get priceChipLabel {
    if (minFcfa == null && maxFcfa == null) {
      return switch (type) {
        ListingType.location => 'Loyer / mois',
        ListingType.vente => 'Prix de vente',
        ListingType.terrain => 'Prix du terrain',
        null => 'Tous les prix',
      };
    }
    final suffix = type == ListingType.location ? ' / mois' : '';
    if (minFcfa != null && maxFcfa != null) {
      return '${formatBound(minFcfa!)} – ${formatBound(maxFcfa!)}$suffix';
    }
    if (maxFcfa != null) return 'Jusqu’à ${formatBound(maxFcfa!)}$suffix';
    return 'Dès ${formatBound(minFcfa!)}$suffix';
  }

  static String formatBound(int amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      final text = millions >= 10 || millions == millions.roundToDouble()
          ? '${millions.round()} M'
          : '${millions.toStringAsFixed(1).replaceFirst('.', ',')} M';
      return text;
    }
    if (amount >= 1000) {
      return '${(amount / 1000).round()} k';
    }
    return '$amount';
  }

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
    kind = null;
    apartmentLayout = null;
    villaStyle = null;
    minFcfa = null;
    maxFcfa = null;
    notifyListeners();
  }

  void setKind(PropertyKind? value) {
    kind = value;
    apartmentLayout = null;
    villaStyle = null;
    notifyListeners();
  }

  void setApartmentLayout(ApartmentLayout? value) {
    apartmentLayout = value;
    if (value == ApartmentLayout.studio) {
      kind = PropertyKind.studio;
    } else if (value != null) {
      kind = PropertyKind.appartement;
    }
    notifyListeners();
  }

  void setVillaStyle(VillaStyle? value) {
    villaStyle = value;
    notifyListeners();
  }

  void setPriceBounds({int? minFcfa, int? maxFcfa}) {
    this.minFcfa = minFcfa;
    this.maxFcfa = maxFcfa;
    notifyListeners();
  }

  void setRecentOnly(bool value) {
    recentOnly = value;
    notifyListeners();
  }

  void apply({String? query, String? city, ListingType? type}) {
    if (query != null) this.query = query;
    this.city = city;
    this.type = type;
    kind = null;
    apartmentLayout = null;
    villaStyle = null;
    minFcfa = null;
    maxFcfa = null;
    recentOnly = false;
    notifyListeners();
  }

  void clear() {
    query = '';
    city = null;
    type = null;
    kind = null;
    apartmentLayout = null;
    villaStyle = null;
    minFcfa = null;
    maxFcfa = null;
    recentOnly = false;
    notifyListeners();
  }
}
