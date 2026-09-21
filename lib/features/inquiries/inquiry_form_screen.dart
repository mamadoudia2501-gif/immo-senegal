import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/broker_repository.dart';
import '../../data/repositories/conversation_repository.dart';
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
  bool _lockedIdentity = false;
  var _prefilled = false;

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null) {
      _messageController.text =
          'Bonjour, je suis intéressé(e) par cette annonce et souhaite être recontacté(e).';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) return;
    _lockedIdentity = true;
    if ((user.displayName ?? '').trim().isNotEmpty) {
      _nameController.text = user.displayName!.trim();
    }
    _phoneController.text = senegalLocalDigits(user.phone);
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
    final inquiry = await context.read<InquiryRepository>().add(
      name: _nameController.text,
      phone: formatSenegalPhone(_phoneController.text),
      message: _messageController.text,
      listingId: widget.listingId,
    );
    if (!mounted) return;
    final listings = context.read<ListingRepository>();
    final listing = inquiry.listingId == null
        ? null
        : listings.byId(inquiry.listingId!);
    final conversation = context
        .read<ConversationRepository>()
        .startFromInquiry(
          inquiry: inquiry,
          listing: listing,
          advertiserPhone: ConversationRepository.ownerPhone(
            listing: listing,
            brokers: context.read<BrokerRepository>(),
          ),
        );
    final auth = context.read<AuthRepository>();
    final chatPath = '/discussion/${conversation.id}';
    if (auth.isLoggedIn) {
      context.go(chatPath);
      return;
    }
    await auth.requestCode(phone: inquiry.phone, name: inquiry.name);
    if (!mounted) return;
    context.go('/connexion/code?next=${Uri.encodeQueryComponent(chatPath)}');
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
                      ? 'Décrivez votre recherche. Après envoi, la discussion continue dans l’application.'
                      : 'Envoyez votre message : un fil de discussion s’ouvre avec l’annonceur, dans l’application.',
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
                enabled: !_lockedIdentity,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Téléphone (Sénégal)',
                  hintText: '77 123 45 67',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  helperText: _lockedIdentity
                      ? 'Numéro de votre compte — requis pour continuer le chat.'
                      : 'Un code WhatsApp mock confirmera ce numéro pour le chat.',
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
