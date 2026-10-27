import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Stylized garment & dashboard icons so all catalog cards and summary cards
// match the design screens offline without external image dependencies.
class ClothingIllustration extends StatelessWidget {
  final String imageKey;
  final double size;

  const ClothingIllustration({
    super.key,
    required this.imageKey,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GarmentPainter(imageKey: imageKey),
      ),
    );
  }
}

class _GarmentPainter extends CustomPainter {
  final String imageKey;

  const _GarmentPainter({required this.imageKey});

  @override
  void paint(Canvas canvas, Size size) {
    switch (imageKey) {
      case 'parachute_jacket':
        _drawJacket(
          canvas,
          size,
          bodyColor: const Color(0xFFA89F99),
          lapelColor: const Color(0xFF7D746E),
          hasBelt: true,
        );
        break;
      case 'relax_jacket':
        _drawJacket(
          canvas,
          size,
          bodyColor: const Color(0xFF9A7B56),
          lapelColor: const Color(0xFF755B3C),
          hasHood: true,
        );
        break;
      case 'villa_jacket':
        _drawJacket(
          canvas,
          size,
          bodyColor: const Color(0xFF2855A6),
          lapelColor: const Color(0xFF1A3A75),
          hasHood: true,
          stripeColor: const Color(0xFFF5B41A),
        );
        break;
      case 'grey_jacket':
        _drawJacket(
          canvas,
          size,
          bodyColor: const Color(0xFF605E61),
          lapelColor: const Color(0xFF474548),
        );
        break;
      case 'pink_jean':
        _drawPants(canvas, size, const Color(0xFFF54E7E), tilted: true);
        break;
      case 'blue_jean':
        _drawPants(canvas, size, const Color(0xFF9BB8D9), tilted: true);
        break;
      case 'brown_jean':
        _drawPants(canvas, size, const Color(0xFF9C7259));
        break;
      case 'black_jeans':
      case 'fabric_trousers':
        _drawPants(canvas, size, const Color(0xFF232629));
        break;
      case 'gryphon_sweatshirt':
        _drawShirt(canvas, size, const Color(0xFFC63628), longSleeve: true);
        break;
      case 'yellow_shirt':
        _drawShirt(canvas, size, const Color(0xFFE5C838), longSleeve: false);
        break;
      case 'blue_shirt':
        _drawShirt(canvas, size, const Color(0xFF7BB1E8), longSleeve: false);
        break;
      case 'blue_nike_shoes':
        _drawShoe(canvas, size, const Color(0xFF3E7BFA));
        break;
      case 'air_jordan_shoes':
        _drawShoe(canvas, size, const Color(0xFFD63B3B));
        break;
      default:
        _drawJacket(
          canvas,
          size,
          bodyColor: const Color(0xFF6E7772),
          lapelColor: const Color(0xFF4E5652),
        );
    }
  }

  void _drawJacket(
    Canvas canvas,
    Size size, {
    required Color bodyColor,
    required Color lapelColor,
    bool hasBelt = false,
    bool hasHood = false,
    Color? stripeColor,
  }) {
    final w = size.width;
    final h = size.height;
    final bodyPaint = Paint()..color = bodyColor;
    final detailPaint = Paint()..color = lapelColor;

    if (hasHood) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.17),
          width: w * 0.34,
          height: h * 0.22,
        ),
        detailPaint,
      );
    }

    // Left and right sleeves
    final leftSleeve = Path()
      ..moveTo(w * 0.28, h * 0.22)
      ..lineTo(w * 0.10, h * 0.74)
      ..lineTo(w * 0.22, h * 0.77)
      ..lineTo(w * 0.32, h * 0.38)
      ..close();
    final rightSleeve = Path()
      ..moveTo(w * 0.72, h * 0.22)
      ..lineTo(w * 0.90, h * 0.74)
      ..lineTo(w * 0.78, h * 0.77)
      ..lineTo(w * 0.68, h * 0.38)
      ..close();
    canvas.drawPath(leftSleeve, bodyPaint);
    canvas.drawPath(rightSleeve, bodyPaint);

    // Torso
    final torso = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.27, h * 0.20, w * 0.46, h * 0.66),
      const Radius.circular(10),
    );
    canvas.drawRRect(torso, bodyPaint);

    // Collar / lapels
    final collar = Path()
      ..moveTo(w * 0.36, h * 0.20)
      ..lineTo(w * 0.50, h * 0.36)
      ..lineTo(w * 0.64, h * 0.20)
      ..close();
    canvas.drawPath(collar, detailPaint);

    // Center zipper / seam
    canvas.drawLine(
      Offset(w * 0.50, h * 0.32),
      Offset(w * 0.50, h * 0.86),
      Paint()
        ..color = lapelColor
        ..strokeWidth = 2,
    );

    if (stripeColor != null) {
      canvas.drawRect(
        Rect.fromLTWH(w * 0.27, h * 0.52, w * 0.46, h * 0.11),
        Paint()..color = stripeColor,
      );
    }

    if (hasBelt) {
      canvas.drawRect(
        Rect.fromLTWH(w * 0.26, h * 0.53, w * 0.48, h * 0.06),
        detailPaint,
      );
      // Buttons
      for (final dy in [0.43, 0.64]) {
        canvas.drawCircle(Offset(w * 0.43, h * dy), 2.5, detailPaint);
        canvas.drawCircle(Offset(w * 0.57, h * dy), 2.5, detailPaint);
      }
    }
  }

  void _drawPants(Canvas canvas, Size size, Color color, {bool tilted = false}) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    canvas.save();
    if (tilted) {
      canvas.translate(w * 0.5, h * 0.5);
      canvas.rotate(-0.12);
      canvas.translate(-w * 0.5, -h * 0.5);
    }

    final path = Path()
      ..moveTo(w * 0.28, h * 0.14)
      ..lineTo(w * 0.72, h * 0.14)
      ..lineTo(w * 0.78, h * 0.86)
      ..lineTo(w * 0.56, h * 0.86)
      ..lineTo(w * 0.50, h * 0.42)
      ..lineTo(w * 0.44, h * 0.86)
      ..lineTo(w * 0.22, h * 0.86)
      ..close();

    canvas.drawPath(path, paint);

    // Waistband line
    canvas.drawLine(
      Offset(w * 0.29, h * 0.20),
      Offset(w * 0.71, h * 0.20),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  void _drawShirt(
    Canvas canvas,
    Size size,
    Color color, {
    required bool longSleeve,
  }) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(w * 0.32, h * 0.18)
      ..lineTo(w * 0.68, h * 0.18)
      ..lineTo(w * 0.88, longSleeve ? h * 0.72 : h * 0.44)
      ..lineTo(w * 0.74, longSleeve ? h * 0.76 : h * 0.49)
      ..lineTo(w * 0.68, h * 0.36)
      ..lineTo(w * 0.68, h * 0.84)
      ..lineTo(w * 0.32, h * 0.84)
      ..lineTo(w * 0.32, h * 0.36)
      ..lineTo(w * 0.26, longSleeve ? h * 0.76 : h * 0.49)
      ..lineTo(w * 0.12, longSleeve ? h * 0.72 : h * 0.44)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawShoe(Canvas canvas, Size size, Color color) {
    final w = size.width;
    final h = size.height;
    final upper = Path()
      ..moveTo(w * 0.18, h * 0.66)
      ..lineTo(w * 0.26, h * 0.36)
      ..lineTo(w * 0.52, h * 0.44)
      ..quadraticBezierTo(w * 0.82, h * 0.50, w * 0.86, h * 0.66)
      ..close();
    canvas.drawPath(upper, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.65, w * 0.72, h * 0.10),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _GarmentPainter oldDelegate) =>
      oldDelegate.imageKey != imageKey;
}

// Aesthetic wooden clothing rack background used on Screen 7's "Add New Clothes" banner
class ClothingRackBanner extends StatelessWidget {
  final VoidCallback onTap;

  const ClothingRackBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 168,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFEDEBE6), Color(0xFFF6F5F2)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ClothingRackPainter(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3A39).withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add New Clothes',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClothingRackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Neutral hat silhouette on left of rack
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.36, h * 0.50),
        width: w * 0.14,
        height: h * 0.72,
      ),
      Paint()..color = const Color(0xFFC9BFB3),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.31, h * 0.52),
        width: w * 0.11,
        height: h * 0.44,
      ),
      Paint()..color = const Color(0xFFACA297),
    );

    // Wooden rack bar & vertical pole
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.23, w * 0.48, 6),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE0CCB3),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.39, h * 0.23, 5, h * 0.77),
      Paint()..color = const Color(0xFFE5E2DC),
    );

    // Draped neutral sweaters/coats on hangers
    final coatColors = [
      const Color(0xFFE6DDD2),
      const Color(0xFFF3EFEA),
      const Color(0xFFD6C9B8),
    ];
    for (int i = 0; i < coatColors.length; i++) {
      final x = w * (0.52 + i * 0.09);
      canvas.drawLine(
        Offset(x, h * 0.25),
        Offset(x, h * 0.36),
        Paint()
          ..color = const Color(0xFFD2CFC8)
          ..strokeWidth = 2,
      );
      final drape = Path()
        ..moveTo(x - 18, h * 0.40)
        ..quadraticBezierTo(x, h * 0.30, x + 18, h * 0.40)
        ..lineTo(x + 28, h)
        ..lineTo(x - 26, h)
        ..close();
      canvas.drawPath(drape, Paint()..color = coatColors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Outline icons matching Home Dashboard summary cards (Screen 2)
class SummaryOutlineIcon extends StatelessWidget {
  final String type; // 'hanger', 'water', 'stack'

  const SummaryOutlineIcon({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 44,
      child: CustomPaint(
        painter: _SummaryIconPainter(type: type),
      ),
    );
  }
}

class _SummaryIconPainter extends CustomPainter {
  final String type;

  const _SummaryIconPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFF141A16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    if (type == 'hanger') {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.22), radius: 5),
        -0.3,
        -4.2,
        false,
        stroke,
      );
      canvas.drawLine(Offset(w * 0.5, h * 0.34), Offset(w * 0.5, h * 0.45), stroke);
      final body = Path()
        ..moveTo(w * 0.08, h * 0.80)
        ..lineTo(w * 0.5, h * 0.45)
        ..lineTo(w * 0.92, h * 0.80)
        ..close();
      canvas.drawPath(body, stroke);
    } else if (type == 'water') {
      final outer = Path()
        ..moveTo(w * 0.5, h * 0.10)
        ..quadraticBezierTo(w * 0.84, h * 0.55, w * 0.76, h * 0.74)
        ..arcToPoint(
          Offset(w * 0.24, h * 0.74),
          radius: Radius.circular(w * 0.27),
          clockwise: true,
        )
        ..quadraticBezierTo(w * 0.16, h * 0.55, w * 0.5, h * 0.10);
      canvas.drawPath(outer, stroke);

      final inner = Path()
        ..moveTo(w * 0.5, h * 0.28)
        ..quadraticBezierTo(w * 0.68, h * 0.56, w * 0.63, h * 0.70)
        ..arcToPoint(
          Offset(w * 0.37, h * 0.70),
          radius: Radius.circular(w * 0.14),
          clockwise: true,
        )
        ..quadraticBezierTo(w * 0.32, h * 0.56, w * 0.5, h * 0.28);
      canvas.drawPath(inner, stroke..strokeWidth = 1.5);
    } else {
      // Folded stack of clothes
      for (int layer = 0; layer < 3; layer++) {
        final dy = layer * 7.0;
        final rect = Path()
          ..moveTo(w * 0.14, h * 0.40 + dy)
          ..lineTo(w * 0.52, h * 0.20 + dy)
          ..lineTo(w * 0.88, h * 0.38 + dy)
          ..lineTo(w * 0.50, h * 0.58 + dy)
          ..close();
        canvas.drawPath(rect, stroke..strokeWidth = 1.6);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SummaryIconPainter oldDelegate) =>
      oldDelegate.type != type;
}
