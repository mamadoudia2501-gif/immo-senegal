import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/listing.dart';
import '../../data/models/story.dart';

class StoryMediaView extends StatelessWidget {
  const StoryMediaView({super.key, required this.media, this.expanded = false});

  final StoryMedia media;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final start = Listing.colorForHue(media.hue);
    final end = Color.lerp(start, Colors.black, 0.42)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [start, end],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                media.isVideo
                    ? Icons.play_circle_fill_rounded
                    : Icons.photo_rounded,
                color: Colors.white,
                size: expanded ? 72 : 36,
              ),
              const SizedBox(height: 8),
              Text(
                media.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: expanded ? 18 : 12,
                ),
              ),
              if (media.isVideo)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Vidéo mock',
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class StoryRingAvatar extends StatelessWidget {
  const StoryRingAvatar({
    super.key,
    required this.initials,
    required this.seed,
    this.seen = false,
    this.size = 64,
    this.child,
  });

  final String initials;
  final String seed;
  final bool seen;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: seen
            ? null
            : const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.gold,
                  AppColors.terracotta,
                ],
              ),
        border: seen
            ? Border.all(color: const Color(0xFFE4D9C8), width: 2)
            : null,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child:
              child ??
              CircleAvatar(
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
