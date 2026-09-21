import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/launchers.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/broker_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/listing_gallery.dart';
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

    final broker = listing.brokerId == null
        ? null
        : context.read<BrokerRepository>().byId(listing.brokerId!);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(listing.kind.label),
            flexibleSpace: FlexibleSpaceBar(
              background: ListingGallery(listing: listing),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (listing.layoutLabel != null)
                        _Fact(
                          icon: listing.kind == PropertyKind.villa
                              ? Icons.villa_outlined
                              : Icons.bed_outlined,
                          label: listing.layoutLabel!,
                        )
                      else if (listing.rooms != null)
                        _Fact(
                          icon: Icons.bed_outlined,
                          label: '${listing.rooms} pièces',
                        ),
                      if (listing.surfaceM2 != null)
                        _Fact(
                          icon: Icons.square_foot,
                          label: '${listing.surfaceM2} m²',
                        ),
                      _Fact(
                        icon: Icons.location_city_outlined,
                        label: listing.neighborhood,
                      ),
                      _Fact(icon: listing.type.icon, label: listing.type.label),
                      _Fact(
                        icon: Icons.payments_outlined,
                        label: listing.type == ListingType.location
                            ? 'Loyer / mois'
                            : listing.type == ListingType.vente
                            ? 'Prix de vente'
                            : 'Prix du terrain',
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
                  if (listing.publisherPhone != null) ...[
                    const SizedBox(height: 28),
                    Text('Annonceur', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      listing.publisherPhone!,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (listing.wasPaid)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Annonce payante (100 FCFA, simulation)'),
                      ),
                  ],
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
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 18,
        shadowColor: AppColors.cardShadow,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE4D9C8))),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.type == ListingType.location
                                  ? 'Loyer / mois'
                                  : listing.type == ListingType.vente
                                  ? 'Prix de vente'
                                  : 'Prix du terrain',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              listing.priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (broker != null) ...[
                        IconButton.filledTonal(
                          tooltip: 'Appeler',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primarySoft,
                            foregroundColor: AppColors.primaryDark,
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () => launchPhone(broker.phone),
                          icon: const Icon(Icons.phone_rounded),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          tooltip: 'WhatsApp',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.sand,
                            foregroundColor: AppColors.primaryDark,
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () => launchWhatsApp(broker.phone),
                          icon: const Icon(Icons.chat_rounded),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const Key('listing-inquiry-cta'),
                    onPressed: () => context.push(
                      '/demande/nouvelle?listingId=${listing.id}',
                    ),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Faire une demande'),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(20),
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
