import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

enum StoryMediaKind {
  image,
  video;

  String get label => switch (this) {
    StoryMediaKind.image => 'Photo',
    StoryMediaKind.video => 'Vidéo',
  };
}

@immutable
class StoryMedia {
  const StoryMedia({
    required this.id,
    required this.label,
    required this.hue,
    this.kind = StoryMediaKind.image,
  });

  final String id;
  final String label;
  final double hue;
  final StoryMediaKind kind;

  bool get isVideo => kind == StoryMediaKind.video;

  static const catalog = <StoryMedia>[
    StoryMedia(id: 'visite', label: 'Visite terrain', hue: 168),
    StoryMedia(id: 'cles', label: 'Remise des clés', hue: 32),
    StoryMedia(id: 'salon', label: 'Salon du bien', hue: 210),
    StoryMedia(id: 'facade', label: 'Façade', hue: 18),
    StoryMedia(
      id: 'video-villa',
      label: 'Visite vidéo villa',
      hue: 188,
      kind: StoryMediaKind.video,
    ),
    StoryMedia(
      id: 'video-quartier',
      label: 'Tour du quartier',
      hue: 92,
      kind: StoryMediaKind.video,
    ),
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'hue': hue,
    'kind': kind.name,
  };

  factory StoryMedia.fromJson(Map<String, dynamic> json) {
    return StoryMedia(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Média',
      hue: (json['hue'] as num?)?.toDouble() ?? 160,
      kind: json['kind'] is String
          ? StoryMediaKind.values.byName(json['kind'] as String)
          : StoryMediaKind.image,
    );
  }
}

enum StoryStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
    StoryStatus.pending => 'En attente',
    StoryStatus.approved => 'Validée',
    StoryStatus.rejected => 'Refusée',
  };
}

enum StorySubmitResult {
  needsAuth,
  needsSubscription,
  notAdvertiser,
  submitted,
}

@immutable
class Story {
  const Story({
    required this.id,
    required this.authorPhone,
    required this.media,
    required this.createdAt,
    this.caption = '',
    this.status = StoryStatus.pending,
    this.reviewedAt,
  });

  final String id;
  final String authorPhone;
  final StoryMedia media;
  final String caption;
  final StoryStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  DateTime get expiresAt =>
      createdAt.add(const Duration(hours: AppConstants.storyTtlHours));

  bool isLive([DateTime? now]) {
    final clock = now ?? DateTime.now();
    return status == StoryStatus.approved && clock.isBefore(expiresAt);
  }

  Story copyWith({StoryStatus? status, DateTime? reviewedAt}) {
    return Story(
      id: id,
      authorPhone: authorPhone,
      media: media,
      caption: caption,
      createdAt: createdAt,
      status: status ?? this.status,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorPhone': authorPhone,
    'media': media.toJson(),
    'caption': caption,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
  };

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      authorPhone: json['authorPhone'] as String,
      media: StoryMedia.fromJson(
        Map<String, dynamic>.from(json['media'] as Map),
      ),
      caption: json['caption'] as String? ?? '',
      status: StoryStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] is String
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
    );
  }
}
