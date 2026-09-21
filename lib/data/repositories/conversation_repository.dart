import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/phone.dart';
import '../models/conversation.dart';
import '../models/inquiry.dart';
import '../models/listing.dart';
import 'broker_repository.dart';

class ConversationRepository extends ChangeNotifier {
  ConversationRepository({
    SharedPreferences? preferences,
    DateTime Function()? clock,
  }) : _preferences = preferences,
       _clock = clock ?? DateTime.now;

  ConversationRepository.remote({DateTime Function()? clock})
    : _preferences = null,
      _clock = clock ?? DateTime.now;

  static const _storageKey = 'immo_senegal_conversations';

  SharedPreferences? _preferences;
  final DateTime Function() _clock;
  final List<Conversation> _conversations = [];
  bool loaded = false;

  DateTime now() => _clock();

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    _conversations
      ..clear()
      ..addAll(_decode(_preferences!.getString(_storageKey)));
    loaded = true;
    notifyListeners();
  }

  /// No-op en local. En Supabase, pousse un fil créé avant la session Auth.
  Future<void> syncRemote() async {}

  Conversation? byId(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  Conversation? byInquiry(String inquiryId) {
    for (final conversation in _conversations) {
      if (conversation.inquiryId == inquiryId) return conversation;
    }
    return null;
  }

  List<Conversation> forParticipant(String phone, {bool isAdmin = false}) {
    if (isAdmin) {
      return [..._conversations]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final local = senegalLocalDigits(phone);
    return _conversations.where((conversation) {
      return senegalLocalDigits(conversation.requesterPhone) == local ||
          (conversation.advertiserPhone != null &&
              senegalLocalDigits(conversation.advertiserPhone!) == local);
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Conversation? forListing({required String listingId, required String phone}) {
    final local = senegalLocalDigits(phone);
    for (final conversation in _conversations) {
      if (conversation.listingId != listingId) continue;
      if (senegalLocalDigits(conversation.requesterPhone) == local ||
          (conversation.advertiserPhone != null &&
              senegalLocalDigits(conversation.advertiserPhone!) == local)) {
        return conversation;
      }
    }
    return null;
  }

  bool canWrite({required Conversation conversation, required String? phone}) {
    if (phone == null) return false;
    final local = senegalLocalDigits(phone);
    if (senegalLocalDigits(conversation.requesterPhone) == local) return true;
    final advertiser = conversation.advertiserPhone;
    return advertiser != null && senegalLocalDigits(advertiser) == local;
  }

  /// L’admin peut tout lire ; seuls demandeur et annonceur écrivent.
  bool canView({
    required Conversation conversation,
    required String? phone,
    bool isAdmin = false,
  }) {
    if (isAdmin) return true;
    return canWrite(conversation: conversation, phone: phone);
  }

  Conversation startFromInquiry({
    required Inquiry inquiry,
    Listing? listing,
    String? advertiserPhone,
  }) {
    final existing = byInquiry(inquiry.id);
    if (existing != null) return existing;
    final createdAt = now();
    final conversation = Conversation(
      id: 'c${createdAt.microsecondsSinceEpoch}',
      inquiryId: inquiry.id,
      listingId: listing?.id ?? inquiry.listingId,
      listingTitle: listing?.title,
      requesterPhone: inquiry.phone,
      requesterName: inquiry.name,
      advertiserPhone: advertiserPhone,
      createdAt: createdAt,
      messages: [
        ChatMessage(
          id: 'm${createdAt.microsecondsSinceEpoch}',
          authorPhone: inquiry.phone,
          body: inquiry.message,
          createdAt: createdAt,
        ),
      ],
    );
    _conversations.insert(0, conversation);
    _persist();
    notifyListeners();
    return conversation;
  }

  ChatMessage? sendMessage({
    required String conversationId,
    required String authorPhone,
    required String body,
  }) {
    final text = body.trim();
    if (text.isEmpty) return null;
    final index = _conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index < 0) return null;
    final conversation = _conversations[index];
    if (!canWrite(conversation: conversation, phone: authorPhone)) {
      return null;
    }
    final createdAt = now();
    final message = ChatMessage(
      id: 'm${createdAt.microsecondsSinceEpoch}',
      authorPhone: authorPhone,
      body: text,
      createdAt: createdAt,
    );
    _conversations[index] = conversation.copyWith(
      messages: [...conversation.messages, message],
    );
    _persist();
    notifyListeners();
    return message;
  }

  static String? ownerPhone({
    required Listing? listing,
    required BrokerRepository brokers,
  }) {
    if (listing == null) return null;
    final publisher = listing.publisherPhone?.trim();
    if (publisher != null && publisher.isNotEmpty) return publisher;
    final brokerId = listing.brokerId;
    if (brokerId == null) return null;
    return brokers.byId(brokerId)?.phone;
  }

  List<Conversation> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            Conversation.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(
      _storageKey,
      jsonEncode(
        _conversations.map((conversation) => conversation.toJson()).toList(),
      ),
    );
  }
}
