import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/illustrated_empty.dart';
import '../../shared/widgets/listing_card.dart';
import '../../shared/widgets/shimmer.dart';
import '../shell/catalog_ready.dart';
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
    final bootstrapped = context.watch<CatalogReady>().ready;
    final filters = context.watch<ListingFilterController>();
    final results = context.watch<ListingRepository>().search(
      query: filters.query,
      city: filters.city,
      type: filters.type,
      kind: filters.kind,
      apartmentLayout: filters.apartmentLayout,
      villaStyle: filters.villaStyle,
      minFcfa: filters.minFcfa,
      maxFcfa: filters.maxFcfa,
      recentOnly: filters.recentOnly,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: Column(
        children: [
          Material(
            color: AppColors.cream,
            elevation: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xE6E4D9C8))),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            key: const Key('search-result-count'),
                            _resultCountLabel(results.length, filters.type),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (filters.hasActiveFilters)
                          TextButton(
                            key: const Key('filter-reset'),
                            onPressed: filters.clear,
                            child: const Text('Effacer les filtres'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: !bootstrapped
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: const [
                      ListingSkeleton(),
                      SizedBox(height: 16),
                      ListingSkeleton(),
                    ],
                  )
                : results.isEmpty
                ? IllustratedEmpty(
                    illustration: EmptyIllustration.search,
                    title: 'Aucun bien ne correspond',
                    message: filters.type == ListingType.location
                        ? 'Aucune location ne correspond. Changez le type de bien, le F (F2–F6) ou le loyer mensuel.'
                        : filters.type == ListingType.vente
                        ? 'Aucune vente ne correspond. Élargissez le prix de vente, le type (appartement, villa) ou la ville.'
                        : 'Essayez une autre ville, un autre type (location, vente, terrain) ou élargissez le budget en FCFA.',
                    actionLabel: filters.hasActiveFilters
                        ? 'Réinitialiser'
                        : null,
                    onAction: filters.hasActiveFilters ? filters.clear : null,
                  )
                : ListView.separated(
                    key: const Key('search-results'),
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

String _resultCountLabel(int count, ListingType? type) {
  final plural = count > 1;
  final noun = switch (type) {
    ListingType.location => plural ? 'locations' : 'location',
    ListingType.vente => plural ? 'ventes' : 'vente',
    ListingType.terrain => plural ? 'terrains' : 'terrain',
    null => plural ? 'biens' : 'bien',
  };
  final found = switch (type) {
    ListingType.location ||
    ListingType.vente => plural ? 'trouvées' : 'trouvée',
    _ => plural ? 'trouvés' : 'trouvé',
  };
  return '$count $noun $found';
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filters});

  final ListingFilterController filters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        if (filters.isHousing) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Type de bien',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in PropertyKind.housing)
                  FilterChip(
                    key: Key('filter-kind-${kind.name}'),
                    label: Text(kind.label),
                    selected: filters.kind == kind,
                    showCheckmark: false,
                    onSelected: (selected) =>
                        filters.setKind(selected ? kind : null),
                  ),
              ],
            ),
          ),
        ],
        if (filters.showApartmentLayouts) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Typologie',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final layout in ApartmentLayout.values)
                  if (layout != ApartmentLayout.studio)
                    FilterChip(
                      key: Key('filter-layout-${layout.name}'),
                      label: Text(layout.label),
                      selected: filters.apartmentLayout == layout,
                      showCheckmark: false,
                      onSelected: (selected) =>
                          filters.setApartmentLayout(selected ? layout : null),
                    ),
              ],
            ),
          ),
        ],
        if (filters.showVillaStyles) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'Style de villa',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final style in VillaStyle.values)
                  FilterChip(
                    key: Key('filter-villa-${style.name}'),
                    label: Text(style.label),
                    selected: filters.villaStyle == style,
                    showCheckmark: false,
                    onSelected: (selected) =>
                        filters.setVillaStyle(selected ? style : null),
                  ),
              ],
            ),
          ),
        ],
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
                label: Text(filters.priceChipLabel),
                selected: filters.minFcfa != null || filters.maxFcfa != null,
                showCheckmark: false,
                onSelected: (_) => _pickPrice(context, filters),
              ),
              const SizedBox(width: 8),
              FilterChip(
                key: const Key('filter-recent'),
                avatar: const Icon(Icons.schedule_rounded, size: 16),
                label: const Text('Récentes'),
                selected: filters.recentOnly,
                showCheckmark: false,
                onSelected: (selected) => filters.setRecentOnly(selected),
              ),
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
                  'Ville / agglomération',
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
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _PriceSheet(filters: filters);
      },
    );
  }
}

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.filters});

  final ListingFilterController filters;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late RangeValues _values;

  ListingType? get _type => widget.filters.type;
  int get _spanMin => PricePreset.spanMin(_type);
  int get _spanMax => PricePreset.spanMax(_type);

  @override
  void initState() {
    super.initState();
    final min = widget.filters.minFcfa ?? _spanMin;
    final max = widget.filters.maxFcfa ?? _spanMax;
    _values = RangeValues(
      min.clamp(_spanMin, _spanMax).toDouble(),
      max.clamp(_spanMin, _spanMax).toDouble(),
    );
  }

  String get _title => switch (_type) {
    ListingType.location => 'Loyer mensuel (FCFA)',
    ListingType.vente => 'Prix de vente (FCFA)',
    ListingType.terrain => 'Prix du terrain (FCFA)',
    null => 'Budget (FCFA)',
  };

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '${ListingFilterController.formatBound(_values.start.round())} – ${ListingFilterController.formatBound(_values.end.round())}${_type == ListingType.location ? ' / mois' : ''}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            RangeSlider(
              values: _values,
              min: _spanMin.toDouble(),
              max: _spanMax.toDouble(),
              divisions: 20,
              labels: RangeLabels(
                ListingFilterController.formatBound(_values.start.round()),
                ListingFilterController.formatBound(_values.end.round()),
              ),
              onChanged: (value) => setState(() => _values = value),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in PricePreset.forType(_type))
                  ActionChip(
                    key: Key(
                      'filter-price-preset-${preset.id ?? preset.label}',
                    ),
                    label: Text(preset.label),
                    onPressed: () {
                      filters.setPriceBounds(
                        minFcfa: preset.minFcfa,
                        maxFcfa: preset.maxFcfa,
                      );
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('filter-price-apply'),
              onPressed: () {
                final min = _values.start.round();
                final max = _values.end.round();
                filters.setPriceBounds(
                  minFcfa: min <= _spanMin ? null : min,
                  maxFcfa: max >= _spanMax ? null : max,
                );
                Navigator.pop(context);
              },
              child: const Text('Appliquer'),
            ),
            TextButton(
              onPressed: () {
                filters.setPriceBounds();
                Navigator.pop(context);
              },
              child: const Text('Tous les prix'),
            ),
          ],
        ),
      ),
    );
  }
}
