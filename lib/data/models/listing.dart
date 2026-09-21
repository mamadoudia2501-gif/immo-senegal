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
    required this.placeholderHue,
    this.brokerId,
    this.publisherPhone,
    this.rooms,
    this.surfaceM2,
    this.featured = false,
    this.isActive = true,
    this.wasPaid = false,
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
  final String? brokerId;
  final String? publisherPhone;
  final double placeholderHue;
  final bool featured;
  final bool isActive;
  final bool wasPaid;

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

  Listing copyWith({bool? isActive}) {
    return Listing(
      id: id,
      title: title,
      city: city,
      neighborhood: neighborhood,
      type: type,
      kind: kind,
      priceFcfa: priceFcfa,
      description: description,
      placeholderHue: placeholderHue,
      brokerId: brokerId,
      publisherPhone: publisherPhone,
      rooms: rooms,
      surfaceM2: surfaceM2,
      featured: featured,
      isActive: isActive ?? this.isActive,
      wasPaid: wasPaid,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'city': city,
    'neighborhood': neighborhood,
    'type': type.name,
    'kind': kind.name,
    'priceFcfa': priceFcfa,
    'rooms': rooms,
    'surfaceM2': surfaceM2,
    'description': description,
    'brokerId': brokerId,
    'publisherPhone': publisherPhone,
    'placeholderHue': placeholderHue,
    'featured': featured,
    'isActive': isActive,
    'wasPaid': wasPaid,
  };

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      neighborhood: json['neighborhood'] as String,
      type: ListingType.values.byName(json['type'] as String),
      kind: PropertyKind.values.byName(json['kind'] as String),
      priceFcfa: json['priceFcfa'] as int,
      rooms: json['rooms'] as int?,
      surfaceM2: json['surfaceM2'] as int?,
      description: json['description'] as String,
      brokerId: json['brokerId'] as String?,
      publisherPhone: json['publisherPhone'] as String?,
      placeholderHue: (json['placeholderHue'] as num).toDouble(),
      featured: json['featured'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      wasPaid: json['wasPaid'] as bool? ?? false,
    );
  }
}
