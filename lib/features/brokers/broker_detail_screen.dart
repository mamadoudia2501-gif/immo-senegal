import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/launchers.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: appCardShadow,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                child: Column(
                  children: [
                    AppAvatar(
                      initials: broker.initials,
                      seed: broker.id,
                      radius: 44,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      broker.name,
                      style: theme.textTheme.headlineSmall,
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
                    const SizedBox(height: 12),
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
          const SizedBox(height: 18),
          Text('À propos', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            broker.bio,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('broker-call-cta'),
                  onPressed: () => launchPhone(broker.phone),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Appeler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('broker-whatsapp-cta'),
                  onPressed: () => launchWhatsApp(broker.phone),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => launchMail(broker.email),
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(broker.email),
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
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}
