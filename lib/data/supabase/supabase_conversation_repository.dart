import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/ids.dart';
import '../../core/utils/phone.dart';
import '../mappers/supabase_mappers.dart';
import '../models/conversation.dart';
import '../models/inquiry.dart';
import '../models/listing.dart';
import '../repositories/conversation_repository.dart';
import 'supabase_schema.dart';

class _PendingConversation {
  const _PendingConversation({
    required this.conversation,
    required this.inquiry,
    this.listing,
    this.advertiserPhone,
  });

  final Conversation conversation;
  final Inquiry inquiry;
  final Listing? listing;
  final String? advertiserPhone;
}

class SupabaseConversationRepository extends ConversationRepository {
  SupabaseConversationRepository(this._client) : super.remote();

  final SupabaseClient _client;
  final List<Conversation> _cache = [];
  _PendingConversation? _pending;

  @override
  List<Conversation> get conversations => List.unmodifiable(_cache);

  @override
  Future<void> load() async {
    final rows = await _client
        .from(SupabaseSchema.conversations)
        .select('*, ${SupabaseSchema.messages}(*)')
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
  Future<void> syncRemote() async {
    await _flushPending();
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
    final conversationId = newUuid();
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
          id: newUuid(),
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
    if (_client.auth.currentUser == null) {
      _pending = _PendingConversation(
        conversation: conversation,
        inquiry: inquiry,
        listing: listing,
        advertiserPhone: advertiserPhone,
      );
      return;
    }
    await _flushPending(
      fallback: _PendingConversation(
        conversation: conversation,
        inquiry: inquiry,
        listing: listing,
        advertiserPhone: advertiserPhone,
      ),
    );
  }

  Future<void> _flushPending({_PendingConversation? fallback}) async {
    final pending = _pending ?? fallback;
    if (pending == null) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      _pending = pending;
      return;
    }
    _pending = null;
    final listingId = pending.listing?.id ?? pending.inquiry.listingId;
    String? advertiserId;
    if (listingId != null) {
      try {
        final owned = await _client
            .from(SupabaseSchema.listings)
            .select('owner_id')
            .eq('id', listingId)
            .maybeSingle();
        advertiserId = owned?['owner_id'] as String?;
      } catch (_) {
        advertiserId = null;
      }
    }
    await _client.from(SupabaseSchema.conversations).insert({
      'id': pending.conversation.id,
      'inquiry_id': pending.inquiry.id,
      'listing_id': listingId,
      'listing_title': pending.listing?.title,
      'requester_id': uid,
      'advertiser_id': advertiserId,
      'requester_phone': pending.inquiry.phone,
      'requester_name': pending.inquiry.name,
      'advertiser_phone': pending.advertiserPhone,
    });
    final first = pending.conversation.messages.first;
    await _client.from(SupabaseSchema.messages).insert({
      'id': first.id,
      'conversation_id': pending.conversation.id,
      'author_id': uid,
      'author_phone': pending.inquiry.phone,
      'body': pending.inquiry.message,
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
      id: newUuid(),
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
      (() async {
        await _flushPending();
        await _client.from(SupabaseSchema.messages).insert({
          'id': message.id,
          'conversation_id': conversationId,
          'author_id': _client.auth.currentUser?.id,
          'author_phone': authorPhone,
          'body': text,
        });
        await load();
      })(),
    );
    return message;
  }

  Conversation _fromNested(Map<String, dynamic> row) {
    return conversationFromRow(
      row,
      messages: nestedMessagesFromConversationRow(row),
    );
  }
}
