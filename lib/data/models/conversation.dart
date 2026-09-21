import 'package:flutter/foundation.dart';

enum MessageStatus {
  sent;

  String get label => 'Envoyé';
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.authorPhone,
    required this.body,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String authorPhone;
  final String body;
  final DateTime createdAt;
  final MessageStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorPhone': authorPhone,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      authorPhone: json['authorPhone'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: MessageStatus.values.byName(
        json['status'] as String? ?? MessageStatus.sent.name,
      ),
    );
  }
}

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.inquiryId,
    required this.requesterPhone,
    required this.requesterName,
    required this.createdAt,
    this.listingId,
    this.listingTitle,
    this.advertiserPhone,
    this.messages = const [],
  });

  final String id;
  final String inquiryId;
  final String? listingId;
  final String? listingTitle;
  final String requesterPhone;
  final String requesterName;
  final String? advertiserPhone;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  DateTime get updatedAt => lastMessage?.createdAt ?? createdAt;

  Conversation copyWith({List<ChatMessage>? messages}) {
    return Conversation(
      id: id,
      inquiryId: inquiryId,
      listingId: listingId,
      listingTitle: listingTitle,
      requesterPhone: requesterPhone,
      requesterName: requesterName,
      advertiserPhone: advertiserPhone,
      createdAt: createdAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'inquiryId': inquiryId,
    'listingId': listingId,
    'listingTitle': listingTitle,
    'requesterPhone': requesterPhone,
    'requesterName': requesterName,
    'advertiserPhone': advertiserPhone,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((message) => message.toJson()).toList(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      inquiryId: json['inquiryId'] as String,
      listingId: json['listingId'] as String?,
      listingTitle: json['listingTitle'] as String?,
      requesterPhone: json['requesterPhone'] as String,
      requesterName: json['requesterName'] as String? ?? 'Demandeur',
      advertiserPhone: json['advertiserPhone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      messages: [
        for (final item in json['messages'] as List? ?? const [])
          if (item is Map)
            ChatMessage.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}
