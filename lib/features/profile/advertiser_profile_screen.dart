import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/launchers.dart';
import '../../core/utils/phone.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/listing_card.dart';

class AdvertiserProfileScreen extends StatelessWidget {
  const AdvertiserProfileScreen({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    if (isReservedAdminPhone(phone)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Profil introuvable.')),
      );
    }

    final auth = context.watch<AuthRepository>();
    final profile = resolveAdvertiserProfile(
      phone: phone,
      registered: auth.byPhone(phone),
    );
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Annonceur')),
        body: const Center(child: Text('Profil introuvable.')),
      );
    }

    final listings = context.watch<ListingRepository>().byPublisher(
      profile.phone,
      publicOnly: true,
    );
    final liveStories = context.watch<StoryRepository>().byAuthor(
      profile.phone,
      publicOnly: true,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(profile.displayName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Row(
            children: [
              AppAvatar(
                initials: profile.initials,
                seed: profile.phone,
                radius: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Annonceur',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: profile.phone,
            keyName: 'advertiser-phone',
          ),
          _InfoTile(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            value: profile.whatsappNumber,
          ),
          if ((profile.otherContact ?? '').trim().isNotEmpty)
            _InfoTile(
              icon: Icons.alternate_email_rounded,
              label: 'Autre contact',
              value: profile.otherContact!.trim(),
            ),
          _InfoTile(
            icon: Icons.place_outlined,
            label: 'Adresse',
            value: [
              if ((profile.address ?? '').trim().isNotEmpty)
                profile.address!.trim(),
              if ((profile.city ?? '').trim().isNotEmpty) profile.city!.trim(),
            ].join(', ').ifEmpty('Non renseignée'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => launchWhatsApp(profile.whatsappNumber),
            icon: const Icon(Icons.chat_rounded),
            label: const Text('WhatsApp'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => launchPhone(profile.phone),
            icon: const Icon(Icons.phone_rounded),
            label: const Text('Appeler'),
          ),
          if (liveStories.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Statuts en cours', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  context.push('/statuts/${senegalLocalDigits(profile.phone)}'),
              child: Text('${liveStories.length} statut(s) à voir'),
            ),
          ],
          if (listings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Annonces', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final listing in listings) ...[
              ListingCard(listing: listing),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.keyName,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(color: AppColors.muted)),
      subtitle: Text(
        key: keyName == null ? null : Key(keyName!),
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          fontSize: 16,
        ),
      ),
    );
  }
}
