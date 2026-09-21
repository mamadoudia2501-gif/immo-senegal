import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/formatters/money_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/repositories/story_repository.dart';

class AdminAdvertisersScreen extends StatelessWidget {
  const AdminAdvertisersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final advertisers = context.watch<AuthRepository>().advertisers;
    final listings = context.watch<ListingRepository>();
    final stories = context.watch<StoryRepository>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Annonceurs')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Comptes annonceurs inscrits. Les identifiants internes ne sont pas affichés.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (advertisers.isEmpty)
            const Text('Aucun annonceur inscrit pour le moment.')
          else
            for (final user in advertisers)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  key: Key(
                    'admin-advertiser-${senegalLocalDigits(user.phone)}',
                  ),
                  title: Text(
                    (user.displayName ?? '').trim().isEmpty
                        ? 'Annonceur'
                        : user.displayName!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${maskSenegalPhone(user.phone)} · '
                    '${listings.byPublisher(user.phone).length} annonce(s) · '
                    '${stories.byAuthor(user.phone).length} statut(s)',
                  ),
                  trailing: Text(
                    user.hasActiveStorySubscription()
                        ? 'Stories ${formatFcfa(AppConstants.storySubscriptionFcfa)}'
                        : 'Sans abo',
                    style: TextStyle(
                      color: user.hasActiveStorySubscription()
                          ? AppColors.primaryDark
                          : AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  onTap: isReservedAdminPhone(user.phone)
                      ? null
                      : () => context.push(
                          '/annonceur/${senegalLocalDigits(user.phone)}',
                        ),
                ),
              ),
        ],
      ),
    );
  }
}
