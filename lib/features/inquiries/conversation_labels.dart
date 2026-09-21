import '../../core/utils/phone.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/broker_repository.dart';

String conversationListingTitle(Conversation conversation) {
  final title = conversation.listingTitle?.trim();
  if (title == null || title.isEmpty) return 'Demande générale';
  return title;
}

String conversationPeerPhone({
  required Conversation conversation,
  required String viewerPhone,
}) {
  final local = senegalLocalDigits(viewerPhone);
  if (senegalLocalDigits(conversation.requesterPhone) == local) {
    return conversation.advertiserPhone ?? '';
  }
  return conversation.requesterPhone;
}

String conversationPeerName({
  required Conversation conversation,
  required String viewerPhone,
  required AuthRepository auth,
  required BrokerRepository brokers,
}) {
  final local = senegalLocalDigits(viewerPhone);
  if (senegalLocalDigits(conversation.requesterPhone) != local) {
    return conversation.requesterName;
  }
  final advertiser = conversation.advertiserPhone;
  if (advertiser == null ||
      advertiser.isEmpty ||
      isReservedAdminPhone(advertiser)) {
    return 'Annonceur';
  }
  final userName = auth.byPhone(advertiser)?.displayName?.trim();
  if (userName != null && userName.isNotEmpty) return userName;
  return brokers.byPhone(advertiser)?.name ?? 'Annonceur';
}

String conversationInitials(String name) {
  final parts = name
      .trim()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

bool messageIsMine(ChatMessage message, String? phone) {
  if (phone == null) return false;
  return senegalLocalDigits(message.authorPhone) == senegalLocalDigits(phone);
}
