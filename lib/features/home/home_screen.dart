import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/auth_widgets.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/listing_card.dart';
import '../../shared/widgets/listing_photo_placeholder.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/shimmer.dart';
import '../search/listing_filter_controller.dart';
import '../shell/catalog_ready.dart';
import '../stories/stories_strip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ready = context.watch<CatalogReady>().ready;
    if (!ready) {
      return const Scaffold(body: SafeArea(child: HomeSkeleton()));
    }

    final listings = context.watch<ListingRepository>();
    final featured = listings.featured();
    final catalog = listings.all();
    final spotlight = featured.isNotEmpty
        ? featured.first
        : (catalog.isNotEmpty ? catalog.first : null);
    final moreFeatured = featured
        .where((item) => item.id != spotlight?.id)
        .toList();
    final recent = catalog
        .where((item) => item.id != spotlight?.id)
        .take(5)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Hero(
                onSearch: () => context.go('/recherche'),
                onPublish: () => openPublishFlow(
                  context,
                  loggedIn: context.read<AuthRepository>().isLoggedIn,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: StoriesStrip()),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Explorer par type',
                subtitle: 'Location, vente ou terrain',
                actionLabel: 'Tout voir',
                onAction: () {
                  context.read<ListingFilterController>().clear();
                  context.go('/recherche');
                },
              ),
            ),
            const SliverToBoxAdapter(child: _CategoryRow()),
            if (catalog.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: EmptyState(
                    icon: Icons.home_work_outlined,
                    title: 'Aucune annonce en ligne',
                    message:
                        'Les biens loués, vendus ou retirés n’apparaissent plus ici.',
                  ),
                ),
              )
            else ...[
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'À la une',
                  subtitle: 'Sélection du jour à Dakar et sur la Petite-Côte',
                ),
              ),
              if (spotlight != null)
                SliverToBoxAdapter(child: _Spotlight(listing: spotlight)),
              if (moreFeatured.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 262,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      scrollDirection: Axis.horizontal,
                      itemCount: moreFeatured.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) => ListingCard(
                        listing: moreFeatured[index],
                        compact: true,
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Villes populaires',
                  subtitle: 'Filtrez en un geste',
                ),
              ),
              const SliverToBoxAdapter(child: _CityChips()),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Récemment ajoutés',
                  subtitle: 'Nouvelles annonces en FCFA',
                ),
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
          ],
        ),
      ),
    );
  }
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Pressable(
        onTap: () => context.push('/bien/${listing.id}'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: appCardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Stack(
              children: [
                ListingPhotoPlaceholder(
                  listing: listing,
                  height: 228,
                  showCaption: false,
                  borderRadius: BorderRadius.zero,
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC053D2C)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TypeBadge(type: listing.type),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'À la une',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${listing.locationLabel} · ${listing.priceLabel}',
                        style: const TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _Hero extends StatelessWidget {
  const _Hero({required this.onSearch, required this.onPublish});

  final VoidCallback onSearch;
  final VoidCallback onPublish;

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
                    const Text(
                      'Bonjour',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 12),
                    PublishCta(onPressed: onPublish, light: true),
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
    return Pressable(
      onTap: () {
        context.read<ListingFilterController>().apply(type: type);
        context.go('/recherche');
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: appCardShadow,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            key: Key('home-category-${type.name}'),
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
    const popular = [
      'Dakar',
      'Pikine',
      'Saly',
      'Thiès',
      'Rufisque',
      'Saint-Louis',
    ];
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
