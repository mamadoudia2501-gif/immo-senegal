import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/inquiry.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/inquiry_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/illustrated_empty.dart';
import '../../shared/widgets/listing_photo_placeholder.dart';

class InquiriesScreen extends StatelessWidget {
  const InquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<InquiryRepository>();
    final inquiries = repo.inquiries;
    final listings = context.read<ListingRepository>();
    final dateFormat = DateFormat.yMMMd('fr_FR').add_Hm();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-inquiry-fab'),
        onPressed: () => context.push('/demande/nouvelle'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle demande'),
      ),
      body: inquiries.isEmpty
          ? IllustratedEmpty(
              illustration: EmptyIllustration.inbox,
              title: 'Pas encore de demande',
              message: 'Décrivez le bien que vous cherchez ou contactez un courtier depuis une annonce. Les demandes restent sur cet appareil.',
              actionLabel: 'Faire une demande',
              onAction: () => context.push('/demande/nouvelle'),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: inquiries.length + (repo.latestId != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (repo.latestId != null && index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: _SubmitBanner(),
                  );
                }
                final inquiryIndex = repo.latestId != null ? index - 1 : index;
                final inquiry = inquiries[inquiryIndex];
                final listing = inquiry.listingId == null
                    ? null
                    : listings.byId(inquiry.listingId!);
                return _InquiryTile(
                  inquiry: inquiry,
                  listing: listing,
                  dateLabel: dateFormat.format(inquiry.createdAt),
                  isLast: inquiryIndex == inquiries.length - 1,
                  highlighted: inquiry.id == repo.latestId,
                  theme: theme,
                );
              },
            ),
    );
  }
}

class _SubmitBanner extends StatelessWidget {
  const _SubmitBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inquiry-success-banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFB7D9C8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.primaryDark),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demande envoyée',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Elle est enregistrée sur cet appareil. Un courtier pourra vous recontacter (simulation locale, sans envoi réel).',
                  style: TextStyle(height: 1.4, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InquiryTile extends StatelessWidget {
  const _InquiryTile({
    required this.inquiry,
    required this.listing,
    required this.dateLabel,
    required this.isLast,
    required this.highlighted,
    required this.theme,
  });

  final Inquiry inquiry;
  final Listing? listing;
  final String dateLabel;
  final bool isLast;
  final bool highlighted;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final linkedListing = listing;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? AppColors.primary
                        : AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFD7E6DC),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: appCardShadow,
                ),
                child: Card(
                  color: highlighted ? const Color(0xFFF7FBF8) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              avatar: Icon(
                                inquiry.status == InquiryStatus.envoyee
                                    ? Icons.send_rounded
                                    : Icons.check_circle_outline,
                                size: 16,
                                color: AppColors.primaryDark,
                              ),
                              label: Text(inquiry.status.label),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.primarySoft,
                              side: BorderSide.none,
                            ),
                            Text(
                              dateLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(inquiry.name, style: theme.textTheme.titleMedium),
                        Text(
                          inquiry.phone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(inquiry.message),
                        if (linkedListing != null) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () =>
                                context.push('/bien/${linkedListing.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.sand.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 72,
                                    child: ListingPhotoPlaceholder(
                                      listing: linkedListing,
                                      height: 56,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          linkedListing.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TypeBadge(
                                          type: linkedListing.type,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
