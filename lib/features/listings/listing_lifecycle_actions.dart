import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/listing_repository.dart';

class ListingStatusBadge extends StatelessWidget {
  const ListingStatusBadge({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final closed = listing.isClosed;
    final color = closed ? AppColors.terracotta : AppColors.primaryDark;
    return Container(
      key: Key('listing-status-${listing.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: closed ? const Color(0xFFF8E6D8) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        listing.ownerStatusLabel,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ListingLifecycleActions extends StatelessWidget {
  const ListingLifecycleActions({
    super.key,
    required this.listing,
    this.compact = false,
  });

  final Listing listing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (listing.isDeleted) return const SizedBox.shrink();
    final close = ListingLifecycle.closeFor(listing.type);
    final canClose =
        listing.lifecycle == ListingLifecycle.actif &&
        close.allowedFor(listing.type);

    if (compact) {
      return PopupMenuButton<String>(
        key: Key('listing-manage-${listing.id}'),
        tooltip: 'Gérer l’annonce',
        onSelected: (value) => _onSelected(context, value),
        itemBuilder: (context) => [
          if (canClose)
            PopupMenuItem(
              value: 'close',
              child: Text(
                close == ListingLifecycle.loue
                    ? 'Marquer Loué'
                    : 'Marquer Vendu',
              ),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Supprimer l’annonce'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Gérer l’annonce', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Une annonce louée, vendue ou supprimée disparaît des recherches et du fil public.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (canClose)
          FilledButton.icon(
            key: Key(
              close == ListingLifecycle.loue
                  ? 'listing-mark-rented'
                  : 'listing-mark-sold',
            ),
            onPressed: () => _close(context, close),
            icon: Icon(
              close == ListingLifecycle.loue
                  ? Icons.key_rounded
                  : Icons.sell_outlined,
            ),
            label: Text(
              close == ListingLifecycle.loue ? 'Marquer Loué' : 'Marquer Vendu',
            ),
          ),
        if (canClose) const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('listing-delete'),
          onPressed: () => _delete(context),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Supprimer l’annonce'),
        ),
      ],
    );
  }

  Future<void> _onSelected(BuildContext context, String value) async {
    if (value == 'close') {
      await _close(context, ListingLifecycle.closeFor(listing.type));
      return;
    }
    if (value == 'delete') {
      await _delete(context);
    }
  }

  Future<void> _close(BuildContext context, ListingLifecycle next) async {
    final ok = await context.read<ListingRepository>().setLifecycle(
      id: listing.id,
      lifecycle: next,
    );
    if (!context.mounted || !ok) return;
    final message = next == ListingLifecycle.loue
        ? 'Annonce marquée comme louée. Elle n’apparaît plus dans les recherches.'
        : 'Annonce marquée comme vendue. Elle n’apparaît plus dans les recherches.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer l’annonce ?'),
          content: const Text(
            'Elle disparaîtra des recherches et de « Mes annonces ». Cette action est définitive (simulation locale).',
          ),
          actions: [
            TextButton(
              key: const Key('listing-delete-cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              key: const Key('listing-delete-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<ListingRepository>().setLifecycle(
      id: listing.id,
      lifecycle: ListingLifecycle.supprimee,
    );
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Annonce supprimée.')));
    if (GoRouterState.of(context).uri.path.startsWith('/bien/')) {
      context.go('/profil');
    }
  }
}
