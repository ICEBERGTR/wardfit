import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/wardfit_logo.dart';

class LoadingScreen extends StatefulWidget {
  final String displayUsername;
  final Future<void> Function()? task;
  final String nextRouteName;
  final bool replaceCurrentOnly;

  const LoadingScreen({
    super.key,
    required this.displayUsername,
    this.task,
    required this.nextRouteName,
    this.replaceCurrentOnly = false,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _runTransition();
  }

  Future<void> _runTransition() async {
    // Run the backend sync alongside a short minimum splash delay
    await Future.wait([
      if (widget.task != null) widget.task!(),
      Future<void>.delayed(const Duration(milliseconds: 1350)),
    ]);

    if (!mounted) return;
    if (widget.replaceCurrentOnly) {
      Navigator.of(context).pushReplacementNamed(widget.nextRouteName);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.nextRouteName,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 56, 36, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top-left greeting
              Text(
                'Hello ${widget.displayUsername}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.splashGreen,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'How are you today?',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.splashGreen,
                ),
              ),

              // Center lime smiley face with curved "l o a d i n g . . ." text
              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                      CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: const SizedBox(
                      width: 240,
                      height: 230,
                      child: CustomPaint(
                        painter: _SmileyCurvedLoadingPainter(),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom WardFit coat hanger logo
              const Center(
                child: WardFitLogo(width: 132),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmileyCurvedLoadingPainter extends CustomPainter {
  const _SmileyCurvedLoadingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const lime = Color(0xFF70DF4C);
    final eyePaint = Paint()..color = lime;

    final cx = size.width / 2;

    // Left and right circular eyes
    canvas.drawCircle(Offset(cx - 56, size.height * 0.28), 16.5, eyePaint);
    canvas.drawCircle(Offset(cx + 56, size.height * 0.28), 16.5, eyePaint);

    // Smile arc
    final smilePaint = Paint()
      ..color = lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.39),
        width: 82,
        height: 54,
      ),
      0.24,
      math.pi - 0.48,
      false,
      smilePaint,
    );

    // Curved "loading..." text positioned along an upward-smiling arc underneath
    const chars = ['l', 'o', 'a', 'd', 'i', 'n', 'g', '.', '.', '.'];
    final arcCenter = Offset(cx, size.height * 0.16);
    const arcRadius = 158.0;
    const totalSpread = 0.86; // radians across bottom of circle
    final startAngle = (math.pi / 2) + (totalSpread / 2);

    for (int i = 0; i < chars.length; i++) {
      final t = i / (chars.length - 1);
      final angle = startAngle - t * totalSpread;

      final x = arcCenter.dx + arcRadius * math.cos(angle);
      final y = arcCenter.dy + arcRadius * math.sin(angle);

      final tp = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: lime,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(x, y);
      // Rotate letter tangentially along the bottom curve
      canvas.rotate(angle - math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
