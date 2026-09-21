import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../data/models/story.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../shared/widgets/story_media_view.dart';

class AdminStoriesScreen extends StatelessWidget {
  const AdminStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<StoryRepository>();
    final auth = context.watch<AuthRepository>();
    final pending = repo.pending();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de statut')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Seules les stories validées sont visibles 24 h par tout le monde.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (pending.isEmpty)
            const Text('Aucune demande en attente.')
          else
            for (final story in pending)
              _PendingCard(
                story: story,
                authorName:
                    auth.byPhone(story.authorPhone)?.displayName ?? 'Annonceur',
              ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.story, required this.authorName});

  final Story story;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 56,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StoryMediaView(media: story.media),
                ),
              ),
              title: Text(
                authorName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${maskSenegalPhone(story.authorPhone)} · ${story.media.label}',
              ),
            ),
            if (story.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(story.caption),
              ),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: Key('admin-story-approve-${story.id}'),
                    onPressed: () => context.read<StoryRepository>().setStatus(
                      id: story.id,
                      status: StoryStatus.approved,
                    ),
                    child: const Text('Valider'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: Key('admin-story-reject-${story.id}'),
                    onPressed: () => context.read<StoryRepository>().setStatus(
                      id: story.id,
                      status: StoryStatus.rejected,
                    ),
                    child: const Text('Refuser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
