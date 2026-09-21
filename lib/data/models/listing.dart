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

  /// Types proposés en Location / Vente (hors terrain).
  static List<PropertyKind> get housing => const [
    PropertyKind.appartement,
    PropertyKind.villa,
    PropertyKind.studio,
    PropertyKind.maison,
    PropertyKind.duplex,
  ];
}

/// Typologie F (Sénégal / France) : F2 = 2 pièces, etc.
enum ApartmentLayout {
  studio(1, 'Studio'),
  f2(2, 'F2'),
  f3(3, 'F3'),
  f4(4, 'F4'),
  f5(5, 'F5'),
  f6(6, 'F6');

  const ApartmentLayout(this.rooms, this.label);

  final int rooms;
  final String label;

  static ApartmentLayout? fromRooms(int? rooms) {
    if (rooms == null) return null;
    return switch (rooms) {
      1 => ApartmentLayout.studio,
      2 => ApartmentLayout.f2,
      3 => ApartmentLayout.f3,
      4 => ApartmentLayout.f4,
      5 => ApartmentLayout.f5,
      >= 6 => ApartmentLayout.f6,
      _ => null,
    };
  }
}

enum VillaStyle {
  basique('Villa basique', 'Basique'),
  standing('Villa standing', 'Standing'),
  duplex('Villa duplex', 'Duplex'),
  piscine('Villa avec piscine', 'Piscine');

  const VillaStyle(this.label, this.chipLabel);

  final String label;
  final String chipLabel;
}

class PricePreset {
  const PricePreset(this.label, this.minFcfa, this.maxFcfa, {this.id});

  final String label;
  final int? minFcfa;
  final int? maxFcfa;
  final String? id;

  static const locationMin = 50000;
  static const locationMax = 2000000;
  static const venteMin = 8000000;
  static const venteMax = 400000000;
  static const terrainMin = 3000000;
  static const terrainMax = 80000000;

  static int spanMin(ListingType? type) => switch (type) {
    ListingType.location => locationMin,
    ListingType.vente => venteMin,
    ListingType.terrain => terrainMin,
    null => locationMin,
  };

  static int spanMax(ListingType? type) => switch (type) {
    ListingType.location => locationMax,
    ListingType.vente => venteMax,
    ListingType.terrain => terrainMax,
    null => venteMax,
  };

  static List<PricePreset> forType(ListingType? type) {
    if (type == ListingType.location) {
      return const [
        PricePreset(
          'Moins de 200 000 / mois',
          null,
          200000,
          id: 'loc-under-200k',
        ),
        PricePreset('200 – 400 000 / mois', 200000, 400000, id: 'loc-200-400k'),
        PricePreset('400 – 800 000 / mois', 400000, 800000, id: 'loc-400-800k'),
        PricePreset(
          'Plus de 800 000 / mois',
          800000,
          null,
          id: 'loc-over-800k',
        ),
      ];
    }
    if (type == ListingType.vente) {
      return const [
        PricePreset('Moins de 40 M', null, 40000000, id: 'sale-under-40m'),
        PricePreset('40 – 100 M', 40000000, 100000000, id: 'sale-40-100m'),
        PricePreset('100 – 200 M', 100000000, 200000000, id: 'sale-100-200m'),
        PricePreset('Plus de 200 M', 200000000, null, id: 'sale-over-200m'),
      ];
    }
    return const [
      PricePreset('Moins de 15 M', null, 15000000),
      PricePreset('15 – 40 M', 15000000, 40000000),
      PricePreset('Plus de 40 M', 40000000, null),
    ];
  }
}

@immutable
class ListingPhoto {
  const ListingPhoto({
    required this.id,
    required this.label,
    required this.hue,
  });

  final String id;
  final String label;
  final double hue;

  static const catalog = <ListingPhoto>[
    ListingPhoto(id: 'facade', label: 'Façade', hue: 32),
    ListingPhoto(id: 'salon', label: 'Salon', hue: 168),
    ListingPhoto(id: 'chambre', label: 'Chambre', hue: 210),
    ListingPhoto(id: 'cuisine', label: 'Cuisine', hue: 18),
    ListingPhoto(id: 'sdb', label: 'Salle d’eau', hue: 195),
    ListingPhoto(id: 'exterieur', label: 'Extérieur', hue: 92),
    ListingPhoto(id: 'piscine', label: 'Piscine', hue: 188),
    ListingPhoto(id: 'vue', label: 'Vue', hue: 145),
  ];

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'hue': hue};

  factory ListingPhoto.fromJson(Map<String, dynamic> json) {
    return ListingPhoto(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Photo',
      hue: (json['hue'] as num?)?.toDouble() ?? 160,
    );
  }
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
    this.villaStyle,
    this.listedAt,
    this.photos = const [],
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
  final VillaStyle? villaStyle;
  final DateTime? listedAt;
  final List<ListingPhoto> photos;

  DateTime get publishedAt => listedAt ?? DateTime.utc(2026, 1, 1);

  double get coverHue => photos.isNotEmpty ? photos.first.hue : placeholderHue;

  String get locationLabel => '$neighborhood, $city';

  ApartmentLayout? get apartmentLayout {
    if (kind != PropertyKind.appartement && kind != PropertyKind.studio) {
      return null;
    }
    return ApartmentLayout.fromRooms(rooms);
  }

  String? get layoutLabel {
    if (kind == PropertyKind.villa) return villaStyle?.label;
    return apartmentLayout?.label;
  }

  String get priceLabel {
    final amount = formatFcfa(priceFcfa);
    return type == ListingType.location ? '$amount / mois' : amount;
  }

  Color get placeholderColor => colorForHue(placeholderHue);

  List<double> get galleryHues {
    if (photos.isNotEmpty) {
      return [for (final photo in photos) photo.hue];
    }
    return [
      placeholderHue,
      (placeholderHue + 22) % 360,
      (placeholderHue + 46) % 360,
    ];
  }

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
      villaStyle: villaStyle,
      listedAt: listedAt,
      photos: photos,
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
    'villaStyle': villaStyle?.name,
    'listedAt': publishedAt.toIso8601String(),
    'photos': photos.map((photo) => photo.toJson()).toList(),
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
      villaStyle: json['villaStyle'] is String
          ? VillaStyle.values.byName(json['villaStyle'] as String)
          : null,
      listedAt: json['listedAt'] is String
          ? DateTime.parse(json['listedAt'] as String)
          : null,
      photos: [
        for (final item in json['photos'] as List? ?? const [])
          if (item is Map)
            ListingPhoto.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}
