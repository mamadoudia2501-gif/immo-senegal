import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/broker_repository.dart';
import '../../data/repositories/listing_repository.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                foregroundColor: AppColors.primaryDark,
                child: Text(
                  broker.initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      broker.agency,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${broker.city} · ${broker.yearsExperience} ans d’expérience',
                    ),
                    Text(
                      broker.specialty,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            broker.bio,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
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
          const SizedBox(height: 24),
          Text(
            'Annonces de ${broker.name}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (listings.isEmpty)
            const Text('Aucune annonce publiée pour le moment.')
          else
            for (final listing in listings) ...[
              ListingCard(listing: listing),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
