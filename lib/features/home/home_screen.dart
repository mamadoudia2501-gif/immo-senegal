import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/listing_card.dart';
import '../search/listing_filter_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listings = context.read<ListingRepository>();
    final featured = listings.featured();
    final recent = listings.all().take(6).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Hero(onSearch: () => context.go('/recherche')),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Explorer',
                actionLabel: 'Tout voir',
                onAction: () {
                  context.read<ListingFilterController>().clear();
                  context.go('/recherche');
                },
              ),
            ),
            const SliverToBoxAdapter(child: _CategoryRow()),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Biens en vedette',
                actionLabel: 'Recherche',
                onAction: () => context.go('/recherche'),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      ListingCard(listing: featured[index], compact: true),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Villes populaires'),
            ),
            const SliverToBoxAdapter(child: _CityChips()),
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Récemment ajoutés'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    ListingCard(listing: recent[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Trouvez une location, une vente ou un terrain au Sénégal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const Key('home-search-cta'),
                onTap: onSearch,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.primaryDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ville, quartier ou type de bien…',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final type in ListingType.values) ...[
            Expanded(child: _CategoryTile(type: type)),
            if (type != ListingType.values.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.type});

  final ListingType type;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: type.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('home-category-${type.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.read<ListingFilterController>().apply(type: type);
          context.go('/recherche');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(type.icon, color: type.color, size: 28),
              const SizedBox(height: 8),
              Text(
                type.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: type.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityChips extends StatelessWidget {
  const _CityChips();

  @override
  Widget build(BuildContext context) {
    const popular = ['Dakar', 'Saly', 'Thiès', 'Saint-Louis', 'Ziguinchor'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: popular.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = popular[index];
          return ActionChip(
            label: Text(city),
            onPressed: () {
              context.read<ListingFilterController>().apply(city: city);
              context.go('/recherche');
            },
          );
        },
      ),
    );
  }
}
