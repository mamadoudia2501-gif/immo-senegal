import 'package:flutter/material.dart';

import '../../data/models/listing.dart';
import 'listing_photo_placeholder.dart';

class ListingGallery extends StatefulWidget {
  const ListingGallery({super.key, required this.listing, this.height = 288});

  final Listing listing;
  final double height;

  @override
  State<ListingGallery> createState() => _ListingGalleryState();
}

class _ListingGalleryState extends State<ListingGallery> {
  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hues = widget.listing.galleryHues;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: hues.length,
          onPageChanged: (value) => setState(() => _index = value),
          itemBuilder: (context, index) {
            return ListingPhotoPlaceholder(
              listing: widget.listing,
              height: null,
              hue: hues[index],
              showCaption: false,
              borderRadius: BorderRadius.zero,
            );
          },
        ),
        Positioned(
          left: 16,
          bottom: 18,
          child: TypeBadge(type: widget.listing.type),
        ),
        Positioned(
          right: 16,
          bottom: 18,
          child: Row(
            children: [
              for (var i = 0; i < hues.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(left: 5),
                  width: i == _index ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: i == _index ? 1 : 0.45,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_index + 1}/${hues.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
