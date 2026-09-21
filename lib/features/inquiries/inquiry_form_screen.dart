import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../data/repositories/inquiry_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/listing_photo_placeholder.dart';

class InquiryFormScreen extends StatefulWidget {
  const InquiryFormScreen({super.key, this.listingId});

  final String? listingId;

  @override
  State<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends State<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null) {
      _messageController.text =
          'Bonjour, je suis intéressé(e) par cette annonce et souhaite être recontacté(e).';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    await context.read<InquiryRepository>().add(
      name: _nameController.text,
      phone: formatSenegalPhone(_phoneController.text),
      message: _messageController.text,
      listingId: widget.listingId,
    );
    if (!mounted) return;
    context.go('/demandes');
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listingId == null
        ? null
        : context.read<ListingRepository>().byId(widget.listingId!);

    return Scaffold(
      appBar: AppBar(title: const Text('Faire une demande')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(
                  listing == null
                      ? 'Décrivez votre recherche. Un courtier pourra vous recontacter (simulation locale).'
                      : 'Le courtier recevra vos coordonnées pour cette annonce (enregistrement local).',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.primaryDark),
                ),
              ),
              if (listing != null) ...[
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    boxShadow: appCardShadow,
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListingPhotoPlaceholder(
                          listing: listing,
                          height: 128,
                          borderRadius: BorderRadius.zero,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${listing.locationLabel} · ${listing.priceLabel}',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              TextFormField(
                key: const Key('inquiry-name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Indiquez votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('inquiry-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (Sénégal)',
                  hintText: '77 123 45 67',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (!isValidSenegalPhone(value ?? '')) {
                    return 'Numéro sénégalais attendu (ex. 77 123 45 67)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('inquiry-message'),
                controller: _messageController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 64),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 10) {
                    return 'Précisez votre besoin en quelques mots';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('inquiry-submit'),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Envoi…' : 'Envoyer la demande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
