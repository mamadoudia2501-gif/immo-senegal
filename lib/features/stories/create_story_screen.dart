import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/formatters/money_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/story.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../shared/widgets/story_media_view.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _caption = TextEditingController();
  StoryMedia? _media;
  var _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    await context.read<AuthRepository>().activateStorySubscription();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _submit() async {
    final media = _media;
    if (media == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une photo ou une vidéo.')),
      );
      return;
    }
    setState(() => _busy = true);
    final result = context.read<StoryRepository>().submit(
      user: context.read<AuthRepository>().currentUser,
      media: media,
      caption: _caption.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == StorySubmitResult.submitted) {
      if (!context.mounted) return;
      context.go('/profil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final user = auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Publier un statut')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/connexion?next=/statuts/nouveau'),
            child: const Text('Se connecter'),
          ),
        ),
      );
    }
    if (user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Publier un statut')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'La publication de statuts est réservée aux annonceurs. Vous pouvez modérer les demandes.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final subscribed = user.hasActiveStorySubscription();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publier un statut')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Montrez vos visites et vos biens. Validé par un admin, visible 24 h.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (!subscribed) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Abonnement stories requis',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatFcfa(AppConstants.storySubscriptionFcfa)} / mois (mock), ${AppConstants.storySubscriptionDays} jours. Paiement simulé, aucun prélèvement réel.',
                    style: const TextStyle(color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('story-pay-confirm'),
                    onPressed: _busy ? null : _pay,
                    child: Text(
                      _busy
                          ? 'Activation…'
                          : 'Payer ${formatFcfa(AppConstants.storySubscriptionFcfa)}',
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Abonnement actif jusqu’au ${_formatUntil(user.storySubscriptionUntil!)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Média (1 photo ou vidéo mock)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final media in StoryMedia.catalog)
                  ChoiceChip(
                    key: Key('story-media-${media.id}'),
                    selected: _media?.id == media.id,
                    onSelected: (_) => setState(() => _media = media),
                    avatar: Icon(
                      media.isVideo
                          ? Icons.videocam_outlined
                          : Icons.photo_outlined,
                      size: 16,
                    ),
                    label: Text(media.label),
                  ),
              ],
            ),
            if (_media != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: StoryMediaView(media: _media!),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('story-caption'),
              controller: _caption,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Légende (optionnel)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('story-submit'),
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Envoi…' : 'Envoyer pour validation'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatUntil(DateTime until) {
    return '${until.day.toString().padLeft(2, '0')}/'
        '${until.month.toString().padLeft(2, '0')}/'
        '${until.year}';
  }
}
