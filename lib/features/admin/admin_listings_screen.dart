import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/listing_photo_placeholder.dart';

class AdminListingsScreen extends StatelessWidget {
  const AdminListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ListingRepository>();
    final userListings = repo.userListings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Modération')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Annonces publiées par les comptes (hors catalogue d’exemple). Activez ou désactivez une fiche.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (userListings.isEmpty)
            const Text('Aucune annonce utilisateur pour le moment.')
          else
            for (final listing in userListings) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: appCardShadow,
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => context.push('/bien/${listing.id}'),
                          leading: SizedBox(
                            width: 64,
                            child: ListingPhotoPlaceholder(
                              listing: listing,
                              height: 52,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          title: Text(listing.title),
                          subtitle: Text(
                            '${listing.locationLabel} · ${listing.priceLabel} · ${listing.ownerStatusLabel}',
                          ),
                          trailing: TypeBadge(
                            type: listing.type,
                            compact: true,
                          ),
                        ),
                        if (listing.lifecycle == ListingLifecycle.actif)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: listing.isActive,
                            activeThumbColor: AppColors.primary,
                            title: Text(
                              listing.isActive
                                  ? 'Annonce visible'
                                  : 'Annonce masquée',
                            ),
                            onChanged: (value) =>
                                repo.setActive(id: listing.id, isActive: value),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Retirée du fil public (${listing.lifecycle.label}).',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
