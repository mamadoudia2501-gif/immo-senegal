import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/formatters/money_formatter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_user.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/listing_repository.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _type = ListingType.vente;
  var _kind = PropertyKind.maison;
  var _layout = ApartmentLayout.f3;
  var _villaStyle = VillaStyle.basique;
  var _city = AppConstants.cities.first;
  var _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _neighborhoodController.dispose();
    _priceController.dispose();
    _roomsController.dispose();
    _surfaceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthRepository>();
    if (!auth.isLoggedIn) {
      context.go('/connexion?next=/annonce/nouvelle');
      return;
    }

    var slot = auth.previewListingSlot();
    if (slot == ListingSlot.needsPayment) {
      final accepted = await _confirmPayment();
      if (accepted != true || !mounted) return;
      slot = await auth.reserveListingSlot(pay: true);
    } else {
      slot = await auth.reserveListingSlot();
    }
    if (slot == ListingSlot.needsPayment ||
        slot == ListingSlot.notAuthenticated) {
      return;
    }
    if (!mounted) return;

    final price = int.parse(
      _priceController.text.replaceAll(RegExp(r'\D'), ''),
    );
    final rooms = int.tryParse(_roomsController.text.trim());
    final surface = int.tryParse(_surfaceController.text.trim());
    final user = auth.currentUser!;
    final listing = Listing(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      city: _city,
      neighborhood: _neighborhoodController.text.trim(),
      type: _type,
      kind: _type == ListingType.terrain ? PropertyKind.terrain : _kind,
      priceFcfa: price,
      description: _descriptionController.text.trim(),
      placeholderHue: (user.phone.hashCode.abs() % 300).toDouble() + 20,
      publisherPhone: user.phone,
      rooms: _type == ListingType.terrain
          ? null
          : _kind == PropertyKind.appartement
          ? _layout.rooms
          : _kind == PropertyKind.studio
          ? 1
          : rooms,
      surfaceM2: surface,
      villaStyle: _kind == PropertyKind.villa ? _villaStyle : null,
      listedAt: DateTime.now(),
      wasPaid: slot == ListingSlot.paid,
    );
    await context.read<ListingRepository>().add(listing);
    if (!mounted) return;
    context.go('/bien/${listing.id}');
  }

  Future<bool?> _confirmPayment() {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quota gratuit épuisé',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Les ${AppConstants.freeListingQuota} annonces gratuites ont été utilisées. '
                'Cette publication coûte ${formatFcfa(AppConstants.extraListingPriceFcfa)} '
                '(paiement simulé, aucun prélèvement réel).',
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('pay-listing-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Payer ${formatFcfa(AppConstants.extraListingPriceFcfa)}',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final user = auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publier une annonce')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            if (user?.isAdmin == true)
              const _QuotaBanner(
                title: 'Compte administrateur',
                message:
                    'Vous pouvez publier autant d’annonces que vous voulez, gratuitement.',
              )
            else if (user != null)
              _QuotaBanner(
                title: user.freeListingsRemaining > 0
                    ? '${user.freeListingsRemaining} annonce${user.freeListingsRemaining > 1 ? 's' : ''} gratuite${user.freeListingsRemaining > 1 ? 's' : ''} restante${user.freeListingsRemaining > 1 ? 's' : ''}'
                    : 'Quota gratuit épuisé',
                message: user.freeListingsRemaining > 0
                    ? 'Ensuite : ${formatFcfa(AppConstants.extraListingPriceFcfa)} par annonce (mock).'
                    : 'La prochaine annonce coûtera ${formatFcfa(AppConstants.extraListingPriceFcfa)} (paiement mock).',
              ),
            const SizedBox(height: 16),
            Text('Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final type in ListingType.values)
                  ChoiceChip(
                    key: Key('create-type-${type.name}'),
                    label: Text(type.label),
                    selected: _type == type,
                    onSelected: (_) => setState(() {
                      _type = type;
                      if (type == ListingType.terrain) {
                        _kind = PropertyKind.terrain;
                      } else if (_kind == PropertyKind.terrain) {
                        _kind = PropertyKind.maison;
                      }
                    }),
                  ),
              ],
            ),
            if (_type != ListingType.terrain) ...[
              const SizedBox(height: 14),
              Text('Genre de bien', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kind in PropertyKind.housing)
                    ChoiceChip(
                      label: Text(kind.label),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                ],
              ),
            ],
            if (_type != ListingType.terrain &&
                _kind == PropertyKind.appartement) ...[
              const SizedBox(height: 14),
              Text('Typologie', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final layout in ApartmentLayout.values)
                    if (layout != ApartmentLayout.studio)
                      ChoiceChip(
                        label: Text(layout.label),
                        selected: _layout == layout,
                        onSelected: (_) => setState(() => _layout = layout),
                      ),
                ],
              ),
            ],
            if (_type != ListingType.terrain &&
                _kind == PropertyKind.villa) ...[
              const SizedBox(height: 14),
              Text('Style de villa', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final style in VillaStyle.values)
                    ChoiceChip(
                      label: Text(style.label),
                      selected: _villaStyle == style,
                      onSelected: (_) => setState(() => _villaStyle = style),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('create-title'),
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: (value) {
                if ((value ?? '').trim().length < 5) {
                  return 'Indiquez un titre plus précis';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text('Ville', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final city in AppConstants.cities)
                  ChoiceChip(
                    key: Key('create-city-$city'),
                    label: Text(city),
                    selected: _city == city,
                    onSelected: (_) => setState(() => _city = city),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('create-neighborhood'),
              controller: _neighborhoodController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Quartier'),
              validator: (value) {
                if ((value ?? '').trim().length < 2) {
                  return 'Indiquez le quartier';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('create-price'),
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: switch (_type) {
                  ListingType.location => 'Loyer mensuel (FCFA)',
                  ListingType.vente => 'Prix de vente (FCFA)',
                  ListingType.terrain => 'Prix du terrain (FCFA)',
                },
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = int.tryParse(
                  (value ?? '').replaceAll(RegExp(r'\D'), ''),
                );
                if (amount == null || amount <= 0) {
                  return 'Indiquez un prix en FCFA';
                }
                return null;
              },
            ),
            if (_type != ListingType.terrain &&
                _kind != PropertyKind.appartement &&
                _kind != PropertyKind.studio) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _roomsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pièces (optionnel)',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _surfaceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Surface m² (optionnel)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('create-description'),
              controller: _descriptionController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 10) {
                  return 'Décrivez le bien en quelques phrases';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('create-listing-submit'),
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      await _submit();
                      if (mounted) setState(() => _submitting = false);
                    },
              child: Text(_submitting ? 'Publication…' : 'Publier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaBanner extends StatelessWidget {
  const _QuotaBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}
