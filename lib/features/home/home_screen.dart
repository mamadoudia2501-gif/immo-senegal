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
                height: 262,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: featured.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                right: 28,
                bottom: -48,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        AppConstants.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Trouvez une location, une vente ou un terrain au Sénégal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        height: 1.22,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: const Key('home-search-cta'),
                        onTap: onSearch,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: AppColors.primaryDark,
                              ),
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
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: appCardShadow,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          key: Key('home-category-${type.name}'),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () {
            context.read<ListingFilterController>().apply(type: type);
            context.go('/recherche');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, color: type.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  type.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: type.color,
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

class _CityChips extends StatelessWidget {
  const _CityChips();

  @override
  Widget build(BuildContext context) {
    const popular = ['Dakar', 'Saly', 'Thiès', 'Saint-Louis', 'Ziguinchor'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: popular.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = popular[index];
          return ActionChip(
            avatar: const Icon(Icons.place_outlined, size: 16),
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
