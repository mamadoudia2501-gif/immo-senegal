import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
              message: 'Contactez un courtier ou décrivez le bien que vous cherchez. Les demandes restent sur cet appareil.',
              actionLabel: 'Faire une demande',
              onAction: () => context.push('/demande/nouvelle'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: inquiries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final inquiry = inquiries[index];
                final listing = inquiry.listingId == null
                    ? null
                    : listings.byId(inquiry.listingId!);
                return Card(
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
                              label: Text(inquiry.status.label),
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              dateFormat.format(inquiry.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          inquiry.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(inquiry.phone),
                        const SizedBox(height: 8),
                        Text(inquiry.message),
                        if (listing != null) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => context.push('/bien/${listing.id}'),
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
                                          fontWeight: FontWeight.w600,
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
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
