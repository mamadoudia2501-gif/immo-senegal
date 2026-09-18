import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/inquiry_repository.dart';
import '../../data/repositories/listing_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/listing_photo_placeholder.dart';

class InquiriesScreen extends StatelessWidget {
  const InquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inquiries = context.watch<InquiryRepository>().inquiries;
    final listings = context.read<ListingRepository>();
    final dateFormat = DateFormat.yMMMd('fr_FR').add_Hm();

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-inquiry-fab'),
        onPressed: () => context.push('/demande/nouvelle'),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande'),
      ),
      body: inquiries.isEmpty
          ? EmptyState(
              icon: Icons.mail_outline_rounded,
              title: 'Pas encore de demande',
              message: 'Décrivez le bien que vous cherchez ou contactez un courtier depuis une annonce. Les demandes restent sur cet appareil.',
              actionLabel: 'Faire une demande',
              onAction: () => context.push('/demande/nouvelle'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
              itemCount: inquiries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final inquiry = inquiries[index];
                final listing = inquiry.listingId == null
                    ? null
                    : listings.byId(inquiry.listingId!);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    boxShadow: appCardShadow,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: Text(inquiry.status.label),
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(
                                dateFormat.format(inquiry.createdAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            inquiry.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            inquiry.phone,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 8),
                          Text(inquiry.message),
                          if (listing != null) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => context.push('/bien/${listing.id}'),
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
                                        listing: listing,
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
                                            listing.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TypeBadge(
                                            type: listing.type,
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
                );
              },
            ),
    );
  }
}
