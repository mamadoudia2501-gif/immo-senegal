import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/broker_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/app_avatar.dart';
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 268,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(listing.kind.label),
            flexibleSpace: FlexibleSpaceBar(
              background: ListingPhotoPlaceholder(
                listing: listing,
                height: null,
                borderRadius: BorderRadius.zero,
                showCaption: false,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TypeBadge(type: listing.type),
                  const SizedBox(height: 12),
                  Text(listing.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          listing.locationLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prix',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          listing.priceLabel,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
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
                  const SizedBox(height: 28),
                  Text('Description', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: AppColors.ink,
                    ),
                  ),
                  if (broker != null) ...[
                    const SizedBox(height: 28),
                    Text('Courtier', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        boxShadow: appCardShadow,
                      ),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          onTap: () => context.push('/courtier/${broker.id}'),
                          leading: AppAvatar(
                            initials: broker.initials,
                            seed: broker.id,
                            radius: 24,
                          ),
                          title: Text(
                            broker.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text('${broker.agency} · ${broker.city}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 108),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: AppColors.cardShadow,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                if (broker != null)
                  IconButton.filledTonal(
                    tooltip: 'Appeler le courtier',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size(52, 52),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('tel:${broker.phone.replaceAll(' ', '')}'),
                    ),
                    icon: const Icon(Icons.phone_rounded),
                  ),
                if (broker != null) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('listing-inquiry-cta'),
                    onPressed: () => context.push(
                      '/demande/nouvelle?listingId=${listing.id}',
                    ),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Faire une demande'),
                  ),
                ),
              ],
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4D9C8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
