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
    storySubscriptionUntil: subscriptionUntil,
  );
}

Listing listingFromRow(Map<String, dynamic> row) {
  final photosRaw = row['listing_photos'];
  final photos = <ListingPhoto>[];
  if (photosRaw is List) {
    final sorted = [...photosRaw]
      ..sort((a, b) {
        final ao = a is Map ? (a['sort_order'] as int? ?? 0) : 0;
        final bo = b is Map ? (b['sort_order'] as int? ?? 0) : 0;
        return ao.compareTo(bo);
      });
    for (final item in sorted) {
      if (item is! Map) continue;
      photos.add(
        ListingPhoto(
          id:
              item['id'] as String? ??
              item['storage_path'] as String? ??
              'photo',
          label: item['label'] as String? ?? 'Photo',
          hue: (item['hue'] as num?)?.toDouble() ?? 160,
        ),
      );
    }
  }
  return Listing(
    id: row['id'] as String,
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
    listedAt: row['listed_at'] is String
        ? DateTime.tryParse(row['listed_at'] as String)
        : null,
    photos: photos,
    lifecycle: listingStatusFromSql(row['status'] as String?),
  );
}

Map<String, dynamic> listingToRow(Listing listing, {required String ownerId}) {
  return {
    'id': listing.id,
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
  };
}

Inquiry inquiryFromRow(Map<String, dynamic> row) {
  return Inquiry(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    phone: row['phone'] as String? ?? '',
    message: row['message'] as String? ?? '',
    listingId: row['listing_id'] as String?,
    createdAt:
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    status: InquiryStatus.values.byName(row['status'] as String? ?? 'envoyee'),
  );
}

ChatMessage chatMessageFromRow(Map<String, dynamic> row) {
  return ChatMessage(
    id: row['id'] as String,
    authorPhone: row['author_phone'] as String? ?? '',
    body: row['body'] as String? ?? '',
    createdAt:
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    status: MessageStatus.sent,
  );
}

Conversation conversationFromRow(
  Map<String, dynamic> row, {
  List<ChatMessage> messages = const [],
}) {
  return Conversation(
    id: row['id'] as String,
    inquiryId: row['inquiry_id'] as String,
    listingId: row['listing_id'] as String?,
    listingTitle: row['listing_title'] as String?,
    requesterPhone: row['requester_phone'] as String? ?? '',
    requesterName: row['requester_name'] as String? ?? 'Demandeur',
    advertiserPhone: row['advertiser_phone'] as String?,
    createdAt:
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    messages: messages,
  );
}

Story storyFromRow(Map<String, dynamic> row) {
  final kind = row['media_kind'] as String? ?? 'image';
  return Story(
    id: row['id'] as String,
    authorPhone: row['author_phone'] as String? ?? '',
    media: StoryMedia(
      id: row['media_path'] as String? ?? 'media',
      label: row['media_label'] as String? ?? 'Média',
      hue: (row['media_hue'] as num?)?.toDouble() ?? 160,
      kind: kind == 'video' ? StoryMediaKind.video : StoryMediaKind.image,
    ),
    caption: row['caption'] as String? ?? '',
    status: StoryStatus.values.byName(row['status'] as String? ?? 'pending'),
    createdAt:
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    reviewedAt: row['reviewed_at'] is String
        ? DateTime.tryParse(row['reviewed_at'] as String)
        : null,
  );
}
