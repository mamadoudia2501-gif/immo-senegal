import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/broker_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/listing_card.dart';

class BrokerDetailScreen extends StatelessWidget {
  const BrokerDetailScreen({super.key, required this.brokerId});

  final String brokerId;

  @override
  Widget build(BuildContext context) {
    final broker = context.read<BrokerRepository>().byId(brokerId);
    if (broker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Courtier introuvable')),
        body: const Center(child: Text('Ce courtier n’est plus référencé.')),
      );
    }

    final listings = context.read<ListingRepository>().byBroker(broker.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(broker.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: appCardShadow,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    AppAvatar(
                      initials: broker.initials,
                      seed: broker.id,
                      radius: 40,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      broker.name,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      broker.agency,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${broker.city} · ${broker.yearsExperience} ans d’expérience',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        broker.specialty,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            broker.bio,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('broker-call-cta'),
            onPressed: () =>
                launchUrl(Uri.parse('tel:${broker.phone.replaceAll(' ', '')}')),
            icon: const Icon(Icons.phone_rounded),
            label: Text('Appeler · ${broker.phone}'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse('mailto:${broker.email}')),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Envoyer un e-mail'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/demande/nouvelle'),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Laisser une demande'),
          ),
          const SizedBox(height: 28),
          Text('Annonces de ${broker.name}', style: theme.textTheme.titleLarge),
          const SizedBox(height: 14),
          if (listings.isEmpty)
            const Text('Aucune annonce publiée pour le moment.')
          else
            for (final listing in listings) ...[
              ListingCard(listing: listing),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}
