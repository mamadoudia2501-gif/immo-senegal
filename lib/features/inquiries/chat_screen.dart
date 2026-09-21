import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/launchers.dart';
import '../../core/utils/phone.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/broker_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../shared/widgets/app_avatar.dart';
import 'conversation_labels.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final auth = context.read<AuthRepository>();
    final phone = auth.currentUser?.phone;
    if (phone == null) return;
    final sent = context.read<ConversationRepository>().sendMessage(
      conversationId: widget.conversationId,
      authorPhone: phone,
      body: _inputController.text,
    );
    if (sent == null) return;
    _inputController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<ConversationRepository>();
    final brokers = context.read<BrokerRepository>();
    final conversation = repo.byId(widget.conversationId);
    final user = auth.currentUser;

    if (conversation == null ||
        user == null ||
        !repo.canView(
          conversation: conversation,
          phone: user.phone,
          isAdmin: user.isAdmin,
        )) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discussion')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Cette discussion n’est pas disponible.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final peerName = conversationPeerName(
      conversation: conversation,
      viewerPhone: user.phone,
      auth: auth,
      brokers: brokers,
    );
    final peerPhone = conversationPeerPhone(
      conversation: conversation,
      viewerPhone: user.phone,
    );
    final canWrite = repo.canWrite(
      conversation: conversation,
      phone: user.phone,
    );
    final listingTitle = conversationListingTitle(conversation);
    final showWhatsApp =
        peerPhone.isNotEmpty && !isReservedAdminPhone(peerPhone);
    final timeFormat = DateFormat.Hm('fr_FR');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(
              initials: conversationInitials(peerName),
              seed: conversation.id,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    listingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (conversation.listingId != null)
            IconButton(
              tooltip: 'Voir l’annonce',
              onPressed: () => context.push('/bien/${conversation.listingId}'),
              icon: const Icon(Icons.home_work_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!canWrite)
            Material(
              color: AppColors.sand.withValues(alpha: 0.7),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lecture seule — vous consultez cette discussion.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showWhatsApp)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('chat-whatsapp'),
                  onPressed: () => launchWhatsApp(peerPhone),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Ouvrir WhatsApp'),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: conversation.messages.length,
              itemBuilder: (context, index) {
                final message = conversation.messages[index];
                final mine = messageIsMine(message, user.phone);
                return _Bubble(
                  message: message,
                  mine: mine,
                  timeLabel: timeFormat.format(message.createdAt),
                );
              },
            ),
          ),
          if (canWrite)
            SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE4D9C8))),
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('chat-input'),
                        controller: _inputController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un message…',
                          filled: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('chat-send'),
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      tooltip: 'Envoyer',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.timeLabel,
  });

  final ChatMessage message;
  final bool mine;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          key: Key('chat-bubble-${message.id}'),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            border: mine ? null : Border.all(color: const Color(0xFFE4D9C8)),
            boxShadow: mine ? null : appCardShadow,
          ),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.body,
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.ink,
                  height: 1.35,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mine ? '$timeLabel · ${message.status.label}' : timeLabel,
                style: TextStyle(
                  color: mine ? const Color(0xD9FFFFFF) : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
