import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WardFitLogo extends StatelessWidget {
  final double width;

  const WardFitLogo({super.key, this.width = 270});

  @override
  Widget build(BuildContext context) {
    final height = width * 0.62;
    final fontSize = width * 0.145;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HangerLogoPainter(),
            ),
          ),
          // Cutout sticker effect around WARDFIT text on the bottom wire
          Positioned(
            bottom: height * 0.02,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: width * 0.03),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'WARDFIT',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: const ['Times New Roman', 'serif'],
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.hangerGreen,
                  height: 1.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HangerLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.hangerGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.024
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final hookRadius = size.width * 0.068;
    final hookCenter = Offset(cx + size.width * 0.008, hookRadius + stroke.strokeWidth);

    // Top hook arc
    final hookRect = Rect.fromCircle(center: hookCenter, radius: hookRadius);
    canvas.drawArc(
      hookRect,
      -math.pi * 0.12,
      -math.pi * 1.38,
      false,
      stroke,
    );

    // Neck down to hanger apex
    final neckTop = Offset(cx, hookCenter.dy + hookRadius * 0.92);
    final apex = Offset(cx, size.height * 0.42);
    canvas.drawLine(neckTop, apex, stroke);

    // Left and right sloped shoulders curving back inward at the bottom bar
    final bottomY = size.height * 0.86;
    final hangerPath = Path()
      ..moveTo(size.width * 0.12, bottomY)
      ..quadraticBezierTo(
        size.width * 0.01,
        bottomY - size.height * 0.02,
        size.width * 0.08,
        bottomY - size.height * 0.11,
      )
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(size.width * 0.92, bottomY - size.height * 0.11)
      ..quadraticBezierTo(
        size.width * 0.99,
        bottomY - size.height * 0.02,
        size.width * 0.88,
        bottomY,
      );

    canvas.drawPath(hangerPath, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UserAvatarBadge extends StatelessWidget {
  final double size;

  const UserAvatarBadge({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A4E54), Color(0xFF2B2E33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: CustomPaint(
          painter: _AvatarPortraitPainter(),
        ),
      ),
    );
  }
}

class _AvatarPortraitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Warm portrait silhouette so avatar renders cleanly offline and in tests
    final bgPaint = Paint()..color = const Color(0xFF5D6268);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Hair back
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.46),
      size.width * 0.34,
      Paint()..color = const Color(0xFF1A1A1D),
    );

    // Orange top shoulder accent
    final shoulderPath = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.72,
        size.width * 0.9,
        size.height,
      )
      ..close();
    canvas.drawPath(shoulderPath, Paint()..color = const Color(0xFFD96B27));

    // Face
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.48, size.height * 0.46),
        width: size.width * 0.42,
        height: size.height * 0.48,
      ),
      Paint()..color = const Color(0xFFE0A37E),
    );

    // Smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.48, size.height * 0.50),
        width: size.width * 0.18,
        height: size.height * 0.12,
      ),
      0.15,
      math.pi - 0.3,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
