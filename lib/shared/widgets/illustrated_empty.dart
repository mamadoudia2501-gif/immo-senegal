import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum EmptyIllustration { search, inbox }

class IllustratedEmpty extends StatelessWidget {
  const IllustratedEmpty({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final EmptyIllustration illustration;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(164, 124),
              painter: switch (illustration) {
                EmptyIllustration.search => _SearchScenePainter(),
                EmptyIllustration.inbox => _InboxScenePainter(),
              },
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sand = Paint()..color = AppColors.sand;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      sand,
    );
    final house = Paint()..color = AppColors.primary;
    final roof = Path()
      ..moveTo(size.width * 0.22, size.height * 0.48)
      ..lineTo(size.width * 0.42, size.height * 0.28)
      ..lineTo(size.width * 0.62, size.height * 0.48)
      ..close();
    canvas.drawPath(roof, house);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.28,
          size.height * 0.48,
          size.width * 0.28,
          size.height * 0.28,
        ),
        const Radius.circular(6),
      ),
      house,
    );
    final glass = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.42), 18, glass);
    canvas.drawLine(
      Offset(size.width * 0.80, size.height * 0.54),
      Offset(size.width * 0.88, size.height * 0.66),
      glass,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InboxScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sand = Paint()..color = AppColors.sand;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      sand,
    );
    final envelope = Paint()..color = AppColors.primary;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.32,
        size.width * 0.56,
        size.height * 0.38,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, envelope);
    final flap = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.36)
      ..lineTo(size.width * 0.5, size.height * 0.54)
      ..lineTo(size.width * 0.78, size.height * 0.36);
    canvas.drawPath(path, flap);
    final stamp = Paint()..color = AppColors.gold;
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.28), 10, stamp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
