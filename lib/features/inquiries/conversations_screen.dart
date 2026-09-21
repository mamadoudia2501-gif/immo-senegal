import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/broker_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/illustrated_empty.dart';
import 'conversation_labels.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final conversations = context.watch<ConversationRepository>();
    final brokers = context.read<BrokerRepository>();
    final user = auth.currentUser;
    final items = user == null
        ? const <Conversation>[]
        : conversations.forParticipant(user.phone, isAdmin: user.isAdmin);
    final timeFormat = DateFormat.Hm('fr_FR');
    final dayFormat = DateFormat.MMMd('fr_FR');

    return Scaffold(
      appBar: AppBar(title: const Text('Mes discussions')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-inquiry-fab'),
        onPressed: () => context.push('/demande/nouvelle'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle demande'),
      ),
      body: user == null
          ? IllustratedEmpty(
              illustration: EmptyIllustration.inbox,
              title: 'Connectez-vous pour discuter',
              message:
                  'Après une demande, le fil continue dans l’application. Un code WhatsApp mock lie le numéro saisi au chat.',
              actionLabel: 'Se connecter',
              onAction: () => context.push('/connexion?next=/demandes'),
            )
          : items.isEmpty
          ? IllustratedEmpty(
              illustration: EmptyIllustration.inbox,
              title: 'Pas encore de discussion',
              message:
                  'Faites une demande sur une annonce : la conversation s’ouvre ici, sans quitter l’application.',
              actionLabel: 'Faire une demande',
              onAction: () => context.push('/demande/nouvelle'),
            )
          : ListView.separated(
              key: const Key('conversations-list'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conversation = items[index];
                final peer = conversationPeerName(
                  conversation: conversation,
                  viewerPhone: user.phone,
                  auth: auth,
                  brokers: brokers,
                );
                final last = conversation.lastMessage;
                final updated = conversation.updatedAt;
                final now = DateTime.now();
                final sameDay =
                    updated.year == now.year &&
                    updated.month == now.month &&
                    updated.day == now.day;
                final timeLabel = sameDay
                    ? timeFormat.format(updated)
                    : dayFormat.format(updated);
                final readOnly =
                    user.isAdmin &&
                    !conversations.canWrite(
                      conversation: conversation,
                      phone: user.phone,
                    );
                return _ConversationTile(
                  conversation: conversation,
                  peerName: peer,
                  preview: last?.body ?? 'Discussion ouverte',
                  timeLabel: timeLabel,
                  readOnly: readOnly,
                );
              },
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.peerName,
    required this.preview,
    required this.timeLabel,
    required this.readOnly,
  });

  final Conversation conversation;
  final String peerName;
  final String preview;
  final String timeLabel;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: appCardShadow,
      ),
      child: Card(
        child: InkWell(
          key: Key('conversation-tile-${conversation.id}'),
          onTap: () => context.push('/discussion/${conversation.id}'),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AppAvatar(
                  initials: conversationInitials(peerName),
                  seed: conversation.id,
                  radius: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              peerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conversationListingTitle(conversation),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      if (readOnly) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Lecture seule',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
