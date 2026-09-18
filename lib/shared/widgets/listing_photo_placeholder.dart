import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/listing.dart';

class ListingPhotoPlaceholder extends StatelessWidget {
  const ListingPhotoPlaceholder({
    super.key,
    required this.listing,
    this.height = 168,
    this.borderRadius,
    this.showCaption = true,
  });

  final Listing listing;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    final compact = (height ?? 160) < 90;
    final start = listing.placeholderColor;
    final end = Color.lerp(start, Colors.black, 0.38)!;

    final image = Stack(
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
        CustomPaint(painter: _SahelPatternPainter(accent: listing.type.color)),
        if (!compact)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x00000000),
                  Color(0x99000000),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
        if (!compact && showCaption)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypeBadge(type: listing.type),
                const Spacer(),
                Text(
                  listing.kind.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                if (listing.surfaceM2 != null)
                  Text(
                    '${listing.surfaceM2} m²',
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          )
        else if (compact)
          Center(
            child: Icon(
              listing.type.icon,
              color: Colors.white.withValues(alpha: 0.92),
              size: (height ?? 56) * 0.42,
            ),
          ),
      ],
    );

    return ClipRRect(
      borderRadius: radius,
      child: height == null
          ? image
          : SizedBox(height: height, width: double.infinity, child: image),
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
        boxShadow: [
          BoxShadow(
            color: type.color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: compact ? 12 : 14, color: Colors.white),
          SizedBox(width: compact ? 4 : 6),
          Text(
            type.label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SahelPatternPainter extends CustomPainter {
  _SahelPatternPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.12),
      size.width * 0.32,
      wash,
    );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 1.02),
      size.width * 0.3,
      wash,
    );

    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.7), 42, ring);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 1.15),
        radius: size.width * 0.55,
      ),
      math.pi,
      math.pi,
      false,
      ring,
    );

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.16);
    for (var x = 10.0; x < size.width; x += 16) {
      for (var y = 10.0; y < size.height; y += 16) {
        canvas.drawCircle(Offset(x, y), 1.05, dot);
      }
    }

    final glyph = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.78), 28, glyph);
  }

  @override
  bool shouldRepaint(covariant _SahelPatternPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
