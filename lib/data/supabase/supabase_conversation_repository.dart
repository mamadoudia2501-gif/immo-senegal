import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/phone.dart';
import '../mappers/supabase_mappers.dart';
import '../models/conversation.dart';
import '../models/inquiry.dart';
import '../models/listing.dart';
import '../repositories/conversation_repository.dart';

class SupabaseConversationRepository extends ConversationRepository {
  SupabaseConversationRepository(this._client) : super.remote();

  final SupabaseClient _client;
  final List<Conversation> _cache = [];

  @override
  List<Conversation> get conversations => List.unmodifiable(_cache);

  @override
  Future<void> load() async {
    final rows = await _client
        .from('conversations')
        .select('*, chat_messages(*)')
        .order('created_at', ascending: false);
    _cache
      ..clear()
      ..addAll([
        for (final row in rows as List)
          if (row is Map) _fromNested(Map<String, dynamic>.from(row)),
      ]);
    loaded = true;
    notifyListeners();
  }

  @override
  Conversation? byId(String id) {
    for (final conversation in _cache) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  @override
  Conversation? byInquiry(String inquiryId) {
    for (final conversation in _cache) {
      if (conversation.inquiryId == inquiryId) return conversation;
    }
    return null;
  }

  @override
  List<Conversation> forParticipant(String phone, {bool isAdmin = false}) {
    if (isAdmin) {
      return [..._cache]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final local = senegalLocalDigits(phone);
    return _cache.where((conversation) {
      return senegalLocalDigits(conversation.requesterPhone) == local ||
          (conversation.advertiserPhone != null &&
              senegalLocalDigits(conversation.advertiserPhone!) == local);
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Conversation startFromInquiry({
    required Inquiry inquiry,
    Listing? listing,
    String? advertiserPhone,
  }) {
    final existing = byInquiry(inquiry.id);
    if (existing != null) return existing;
    final createdAt = now();
    final conversationId = 'c-${inquiry.id}';
    final optimistic = Conversation(
      id: conversationId,
      inquiryId: inquiry.id,
      listingId: listing?.id ?? inquiry.listingId,
      listingTitle: listing?.title,
      requesterPhone: inquiry.phone,
      requesterName: inquiry.name,
      advertiserPhone: advertiserPhone,
      createdAt: createdAt,
      messages: [
        ChatMessage(
          id: 'm-${inquiry.id}-open',
          authorPhone: inquiry.phone,
          body: inquiry.message,
          createdAt: createdAt,
        ),
      ],
    );
    _cache.insert(0, optimistic);
    notifyListeners();
    unawaited(
      _persistConversation(
        conversation: optimistic,
        inquiry: inquiry,
        listing: listing,
        advertiserPhone: advertiserPhone,
      ),
    );
    return optimistic;
  }

  Future<void> _persistConversation({
    required Conversation conversation,
    required Inquiry inquiry,
    Listing? listing,
    String? advertiserPhone,
  }) async {
    await _client.from('conversations').insert({
      'id': conversation.id,
      'inquiry_id': inquiry.id,
      'listing_id': listing?.id ?? inquiry.listingId,
      'listing_title': listing?.title,
      'requester_id': _client.auth.currentUser?.id,
      'requester_phone': inquiry.phone,
      'requester_name': inquiry.name,
      'advertiser_phone': advertiserPhone,
    });
    await _client.from('chat_messages').insert({
      'id': conversation.messages.first.id,
      'conversation_id': conversation.id,
      'author_id': _client.auth.currentUser?.id,
      'author_phone': inquiry.phone,
      'body': inquiry.message,
    });
    await load();
  }

  @override
  ChatMessage? sendMessage({
    required String conversationId,
    required String authorPhone,
    required String body,
  }) {
    final text = body.trim();
    if (text.isEmpty) return null;
    final conversation = byId(conversationId);
    if (conversation == null) return null;
    if (!canWrite(conversation: conversation, phone: authorPhone)) {
      return null;
    }
    final createdAt = now();
    final message = ChatMessage(
      id: 'pending-$createdAt',
      authorPhone: authorPhone,
      body: text,
      createdAt: createdAt,
    );
    final index = _cache.indexWhere((item) => item.id == conversationId);
    if (index >= 0) {
      _cache[index] = conversation.copyWith(
        messages: [...conversation.messages, message],
      );
      notifyListeners();
    }
    unawaited(
      _client
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'author_id': _client.auth.currentUser?.id,
            'author_phone': authorPhone,
            'body': text,
          })
          .then((_) => load()),
    );
    return message;
  }

  Conversation _fromNested(Map<String, dynamic> row) {
    final raw = row['chat_messages'];
    final messages = <ChatMessage>[];
    if (raw is List) {
      final items = [
        for (final item in raw)
          if (item is Map) chatMessageFromRow(Map<String, dynamic>.from(item)),
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      messages.addAll(items);
    }
    return conversationFromRow(row, messages: messages);
  }
}
