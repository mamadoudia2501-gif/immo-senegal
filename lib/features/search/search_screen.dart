import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/listing_card.dart';
import 'listing_filter_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _queryController;
  late final ListingFilterController _filters;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _filters = context.read<ListingFilterController>();
    _queryController = TextEditingController(text: _filters.query);
    _filters.addListener(_syncQueryFromFilters);
    _ready = true;
  }

  void _syncQueryFromFilters() {
    if (_queryController.text != _filters.query) {
      _queryController.value = TextEditingValue(
        text: _filters.query,
        selection: TextSelection.collapsed(offset: _filters.query.length),
      );
    }
  }

  @override
  void dispose() {
    if (_ready) {
      _filters.removeListener(_syncQueryFromFilters);
      _queryController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = context.watch<ListingFilterController>();
    final results = context.read<ListingRepository>().search(
      query: filters.query,
      city: filters.city,
      type: filters.type,
      priceRange: filters.priceRange,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              key: const Key('search-query-field'),
              controller: _queryController,
              onChanged: filters.setQuery,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Rechercher un bien, un quartier…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          _FilterBar(filters: filters),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length} bien${results.length > 1 ? 's' : ''} trouvé${results.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Aucun bien ne correspond',
                    message: 'Essayez une autre ville, un autre type (location, vente, terrain) ou élargissez le budget en FCFA.',
                    actionLabel: filters.hasActiveFilters
                        ? 'Réinitialiser'
                        : null,
                    onAction: filters.hasActiveFilters ? filters.clear : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) =>
                        ListingCard(listing: results[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filters});

  final ListingFilterController filters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: filters.type == null,
                showCheckmark: false,
                onSelected: (_) => filters.setType(null),
              ),
              for (final type in ListingType.values)
                FilterChip(
                  key: Key('filter-type-${type.name}'),
                  avatar: Icon(type.icon, size: 16, color: type.color),
                  label: Text(type.label),
                  selected: filters.type == type,
                  showCheckmark: false,
                  onSelected: (selected) =>
                      filters.setType(selected ? type : null),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                avatar: const Icon(Icons.place_outlined, size: 16),
                label: Text(filters.city ?? 'Toutes les villes'),
                selected: filters.city != null,
                showCheckmark: false,
                onSelected: (_) => _pickCity(context, filters),
              ),
              const SizedBox(width: 8),
              FilterChip(
                key: const Key('filter-price'),
                avatar: const Icon(Icons.payments_outlined, size: 16),
                label: Text(filters.priceRange.label),
                selected: filters.priceRange != PriceRange.all,
                showCheckmark: false,
                onSelected: (_) => _pickPrice(context, filters),
              ),
              if (filters.hasActiveFilters) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.close, size: 16),
                  label: const Text('Effacer'),
                  onPressed: filters.clear,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCity(
    BuildContext context,
    ListingFilterController filters,
  ) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Choisir une ville',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.public_outlined),
                title: const Text('Toutes les villes'),
                selected: filters.city == null,
                onTap: () => Navigator.pop(context, ''),
              ),
              for (final city in AppConstants.cities)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(city),
                  selected: filters.city == city,
                  onTap: () => Navigator.pop(context, city),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    filters.setCity(selected.isEmpty ? null : selected);
  }

  Future<void> _pickPrice(
    BuildContext context,
    ListingFilterController filters,
  ) async {
    final selected = await showModalBottomSheet<PriceRange>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Budget (FCFA)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final range in PriceRange.values)
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(range.label),
                  selected: filters.priceRange == range,
                  onTap: () => Navigator.pop(context, range),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) filters.setPriceRange(selected);
  }
}
