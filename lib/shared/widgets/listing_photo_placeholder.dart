import 'package:flutter/material.dart';

import '../../data/models/listing.dart';

class ListingPhotoPlaceholder extends StatelessWidget {
  const ListingPhotoPlaceholder({
    super.key,
    required this.listing,
    this.height = 160,
    this.borderRadius,
  });

  final Listing listing;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final color = listing.placeholderColor;
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, Color.lerp(color, Colors.black, 0.28)!],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                bottom: -28,
                child: Icon(
                  listing.type.icon,
                  size: height < 90 ? 64 : 140,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              if (height >= 90)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TypeBadge(type: listing.type),
                      const Spacer(),
                      Text(
                        listing.kind.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (listing.surfaceM2 != null)
                        Text(
                          '${listing.surfaceM2} m²',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Center(
                  child: Icon(
                    listing.type.icon,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: height * 0.45,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type, this.compact = false});

  final ListingType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: type.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}
