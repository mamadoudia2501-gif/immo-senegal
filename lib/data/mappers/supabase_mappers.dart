import '../models/app_user.dart';
import '../models/conversation.dart';
import '../models/inquiry.dart';
import '../models/listing.dart';
import '../models/story.dart';

String listingStatusToSql(ListingLifecycle lifecycle) => switch (lifecycle) {
  ListingLifecycle.actif => 'active',
  ListingLifecycle.loue => 'loue',
  ListingLifecycle.vendu => 'vendu',
  ListingLifecycle.supprimee => 'supprimee',
};

ListingLifecycle listingStatusFromSql(String? raw) => switch (raw) {
  'loue' => ListingLifecycle.loue,
  'vendu' => ListingLifecycle.vendu,
  'supprimee' => ListingLifecycle.supprimee,
  _ => ListingLifecycle.actif,
};

UserRole userRoleFromSql(String? raw) => switch (raw) {
  'admin' => UserRole.admin,
  'visitor' => UserRole.visitor,
  _ => UserRole.advertiser,
};

String _asText(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

DateTime? _asDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}

AppUser profileFromRow(
  Map<String, dynamic> row, {
  DateTime? subscriptionUntil,
}) {
  return AppUser(
    phone: row['phone'] as String? ?? '',
    displayName: row['display_name'] as String?,
    role: userRoleFromSql(row['role'] as String?),
    freeListingsRemaining: row['free_listings_remaining'] as int? ?? 4,
    publishedCount: row['published_count'] as int? ?? 0,
    paidCount: row['paid_count'] as int? ?? 0,
    whatsapp: row['whatsapp'] as String?,
    otherContact: row['other_contact'] as String?,
    address: row['address'] as String?,
    city: row['city'] as String?,
    storySubscriptionUntil:
        subscriptionUntil ?? _asDate(row['story_subscription_until']),
  );
}

dynamic _firstPresent(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];
    if (value != null) return value;
  }
  return null;
}

List<ListingPhoto> photosFromListingRow(Map<String, dynamic> row) {
  final photosRaw = _firstPresent(row, ['images', 'photos', 'listing_photos']);
  final fallbackHue = (row['placeholder_hue'] as num?)?.toDouble() ?? 160;
  final photos = <ListingPhoto>[];

  if (photosRaw is List) {
    final sorted = [...photosRaw]
      ..sort((a, b) {
        final ao = a is Map ? (a['sort_order'] as int? ?? 0) : 0;
        final bo = b is Map ? (b['sort_order'] as int? ?? 0) : 0;
        return ao.compareTo(bo);
      });
    for (final item in sorted) {
      if (item is String && item.isNotEmpty) {
        photos.add(ListingPhoto(id: item, label: 'Photo', hue: fallbackHue));
        continue;
      }
      if (item is! Map) continue;
      final id =
          item['id'] as String? ??
          item['storage_path'] as String? ??
          item['url'] as String? ??
          item['path'] as String? ??
          'photo';
      photos.add(
        ListingPhoto(
          id: id,
          label: item['label'] as String? ?? 'Photo',
          hue: (item['hue'] as num?)?.toDouble() ?? fallbackHue,
        ),
      );
    }
  }

  if (photos.isEmpty) {
    final url = _asText(
      _firstPresent(row, ['image_url', 'cover_url', 'cover_path']),
    );
    if (url.isNotEmpty) {
      photos.add(ListingPhoto(id: url, label: 'Photo', hue: fallbackHue));
    }
  }
  return photos;
}

List<Map<String, dynamic>> listingImagesPayload(List<ListingPhoto> photos) {
  return [
    for (var i = 0; i < photos.length; i++)
      {
        'id': photos[i].id,
        'storage_path': photos[i].id,
        'label': photos[i].label,
        'hue': photos[i].hue,
        'sort_order': i,
      },
  ];
}

Listing listingFromRow(Map<String, dynamic> row) {
  return Listing(
    id: row['id'].toString(),
    title: row['title'] as String? ?? '',
    city: row['city'] as String? ?? '',
    neighborhood: row['neighborhood'] as String? ?? '',
    type: ListingType.values.byName(row['type'] as String? ?? 'vente'),
    kind: PropertyKind.values.byName(row['kind'] as String? ?? 'maison'),
    priceFcfa: row['price_fcfa'] as int? ?? 0,
    description: row['description'] as String? ?? '',
    placeholderHue: (row['placeholder_hue'] as num?)?.toDouble() ?? 160,
    brokerId: row['broker_id'] as String?,
    publisherPhone: row['publisher_phone'] as String?,
    rooms: row['rooms'] as int?,
    surfaceM2: row['surface_m2'] as int?,
    featured: row['featured'] as bool? ?? false,
    isActive: row['is_active'] as bool? ?? true,
    wasPaid: row['was_paid'] as bool? ?? false,
    villaStyle: row['villa_style'] is String
        ? VillaStyle.values.byName(row['villa_style'] as String)
        : null,
    listedAt: _asDate(row['listed_at']),
    photos: photosFromListingRow(row),
    lifecycle: listingStatusFromSql(row['status'] as String?),
  );
}

Map<String, dynamic> listingToRow(
  Listing listing, {
  required String ownerId,
  bool includeId = true,
}) {
  return {
    if (includeId) 'id': listing.id,
    'owner_id': ownerId,
    'title': listing.title,
    'city': listing.city,
    'neighborhood': listing.neighborhood,
    'type': listing.type.name,
    'kind': listing.kind.name,
    'price_fcfa': listing.priceFcfa,
    'rooms': listing.rooms,
    'surface_m2': listing.surfaceM2,
    'description': listing.description,
    'broker_id': listing.brokerId,
    'publisher_phone': listing.publisherPhone,
    'placeholder_hue': listing.placeholderHue,
    'featured': listing.featured,
    'is_active': listing.isActive,
    'was_paid': listing.wasPaid,
    'villa_style': listing.villaStyle?.name,
    'listed_at': listing.publishedAt.toIso8601String(),
    'status': listingStatusToSql(listing.lifecycle),
    'images': listingImagesPayload(listing.photos),
  };
}

Inquiry inquiryFromRow(Map<String, dynamic> row) {
  return Inquiry(
    id: row['id'].toString(),
    name: row['name'] as String? ?? '',
    phone: row['phone'] as String? ?? '',
    message: row['message'] as String? ?? '',
    listingId: row['listing_id']?.toString(),
    createdAt: _asDate(row['created_at']) ?? DateTime.now(),
    status: InquiryStatus.values.byName(row['status'] as String? ?? 'envoyee'),
  );
}

ChatMessage chatMessageFromRow(Map<String, dynamic> row) {
  return ChatMessage(
    id: row['id'].toString(),
    authorPhone: _asText(
      _firstPresent(row, ['author_phone', 'sender_phone', 'phone']),
    ),
    body: _asText(_firstPresent(row, ['body', 'content', 'text', 'message'])),
    createdAt: _asDate(row['created_at']) ?? DateTime.now(),
    status: MessageStatus.sent,
  );
}

Conversation conversationFromRow(
  Map<String, dynamic> row, {
  List<ChatMessage> messages = const [],
}) {
  return Conversation(
    id: row['id'].toString(),
    inquiryId: row['inquiry_id'].toString(),
    listingId: row['listing_id']?.toString(),
    listingTitle: row['listing_title'] as String?,
    requesterPhone: row['requester_phone'] as String? ?? '',
    requesterName: row['requester_name'] as String? ?? 'Demandeur',
    advertiserPhone: row['advertiser_phone'] as String?,
    createdAt: _asDate(row['created_at']) ?? DateTime.now(),
    messages: messages,
  );
}

List<ChatMessage> nestedMessagesFromConversationRow(Map<String, dynamic> row) {
  final raw = _firstPresent(row, ['messages', 'chat_messages']);
  if (raw is! List) return const [];
  final items = [
    for (final item in raw)
      if (item is Map) chatMessageFromRow(Map<String, dynamic>.from(item)),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return items;
}

Story storyFromRow(Map<String, dynamic> row) {
  final kind = row['media_kind'] as String? ?? 'image';
  return Story(
    id: row['id'].toString(),
    authorPhone: row['author_phone'] as String? ?? '',
    media: StoryMedia(
      id: row['media_path'] as String? ?? 'media',
      label: row['media_label'] as String? ?? 'Média',
      hue: (row['media_hue'] as num?)?.toDouble() ?? 160,
      kind: kind == 'video' ? StoryMediaKind.video : StoryMediaKind.image,
    ),
    caption: row['caption'] as String? ?? '',
    status: StoryStatus.values.byName(row['status'] as String? ?? 'pending'),
    createdAt: _asDate(row['created_at']) ?? DateTime.now(),
    reviewedAt: _asDate(row['reviewed_at']),
  );
}
