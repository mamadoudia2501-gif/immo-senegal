import 'package:flutter/material.dart';

import '../../core/formatters/money_formatter.dart';
import '../../core/theme/app_theme.dart';

enum ListingType {
  location,
  vente,
  terrain;

  String get label => switch (this) {
    ListingType.location => 'Location',
    ListingType.vente => 'Vente',
    ListingType.terrain => 'Terrain',
  };

  IconData get icon => switch (this) {
    ListingType.location => Icons.apartment_rounded,
    ListingType.vente => Icons.home_work_rounded,
    ListingType.terrain => Icons.terrain_rounded,
  };

  Color get color => switch (this) {
    ListingType.location => AppColors.primary,
    ListingType.vente => AppColors.terracotta,
    ListingType.terrain => AppColors.gold,
  };
}

enum PropertyKind {
  appartement,
  villa,
  maison,
  studio,
  duplex,
  bureau,
  terrain;

  String get label => switch (this) {
    PropertyKind.appartement => 'Appartement',
    PropertyKind.villa => 'Villa',
    PropertyKind.maison => 'Maison',
    PropertyKind.studio => 'Studio',
    PropertyKind.duplex => 'Duplex',
    PropertyKind.bureau => 'Bureau',
    PropertyKind.terrain => 'Terrain',
  };
}

enum PriceRange {
  all(null, null, 'Tous les prix'),
  under300k(0, 300000, 'Moins de 300 000'),
  from300kTo2m(300000, 2000000, '300 000 – 2 M'),
  from2mTo30m(2000000, 30000000, '2 M – 30 M'),
  from30mTo100m(30000000, 100000000, '30 M – 100 M'),
  over100m(100000000, null, 'Plus de 100 M');

  const PriceRange(this.minFcfa, this.maxFcfa, this.label);

  final int? minFcfa;
  final int? maxFcfa;
  final String label;
}

@immutable
class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.city,
    required this.neighborhood,
    required this.type,
    required this.kind,
    required this.priceFcfa,
    required this.description,
    required this.brokerId,
    required this.placeholderHue,
    this.rooms,
    this.surfaceM2,
    this.featured = false,
  });

  final String id;
  final String title;
  final String city;
  final String neighborhood;
  final ListingType type;
  final PropertyKind kind;
  final int priceFcfa;
  final int? rooms;
  final int? surfaceM2;
  final String description;
  final String brokerId;
  final double placeholderHue;
  final bool featured;

  String get locationLabel => '$neighborhood, $city';

  String get priceLabel {
    final amount = formatFcfa(priceFcfa);
    return type == ListingType.location ? '$amount / mois' : amount;
  }

  Color get placeholderColor => colorForHue(placeholderHue);

  List<double> get galleryHues => [
    placeholderHue,
    (placeholderHue + 22) % 360,
    (placeholderHue + 46) % 360,
  ];

  static Color colorForHue(double hue) =>
      HSVColor.fromAHSV(1, hue, 0.42, 0.62).toColor();
}
