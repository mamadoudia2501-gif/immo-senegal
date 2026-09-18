import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/broker_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/listing_photo_placeholder.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final listing = context.read<ListingRepository>().byId(listingId);
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bien introuvable')),
        body: const Center(child: Text('Cette annonce n’est plus disponible.')),
      );
    }

    final broker = context.read<BrokerRepository>().byId(listing.brokerId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(listing.kind.label)),
      body: ListView(
        children: [
          ListingPhotoPlaceholder(
            listing: listing,
            height: 220,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypeBadge(type: listing.type),
                const SizedBox(height: 10),
                Text(
                  listing.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        listing.locationLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  listing.priceLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (listing.rooms != null)
                      _Fact(
                        icon: Icons.bed_outlined,
                        label: '${listing.rooms} pièces',
                      ),
                    if (listing.surfaceM2 != null)
                      _Fact(
                        icon: Icons.square_foot,
                        label: '${listing.surfaceM2} m²',
                      ),
                    _Fact(icon: listing.type.icon, label: listing.type.label),
                    const _Fact(
                      icon: Icons.payments_outlined,
                      label: 'Prix en FCFA',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Description',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.description,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                if (broker != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Courtier',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      onTap: () => context.push('/courtier/${broker.id}'),
                      leading: CircleAvatar(child: Text(broker.initials)),
                      title: Text(
                        broker.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${broker.agency} · ${broker.city}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (broker != null)
                IconButton.filledTonal(
                  tooltip: 'Appeler le courtier',
                  onPressed: () => launchUrl(
                    Uri.parse('tel:${broker.phone.replaceAll(' ', '')}'),
                  ),
                  icon: const Icon(Icons.phone_rounded),
                ),
              if (broker != null) const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('listing-inquiry-cta'),
                  onPressed: () =>
                      context.push('/demande/nouvelle?listingId=${listing.id}'),
                  child: const Text('Faire une demande'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
