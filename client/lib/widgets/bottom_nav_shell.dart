import 'package:flutter/material.dart';
import '../services/wardrobe_state.dart';
import '../theme/app_theme.dart';
import 'chatbot_sheet.dart';

class WardFitBottomBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int>? onTabSelected;

  const WardFitBottomBar({
    super.key,
    required this.activeIndex,
    this.onTabSelected,
  });

  void _handleTap(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }
    // When tapped from a pushed screen (Calendar, Catalog, Add Clothes),
    // switch tab on the root shell and pop back to main navigation.
    final state = WardrobeScope.of(context);
    state.setTab(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChatbotSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
        child: Row(
          children: [
            // White pill-shaped navigation bar on the left
            Expanded(
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavTabItem(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      selected: activeIndex == 0,
                      onTap: () => _handleTap(context, 0),
                    ),
                    _NavTabItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      selected: activeIndex == 1,
                      onTap: () => _handleTap(context, 1),
                    ),
                    _NavTabItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      selected: activeIndex == 2,
                      onTap: () => _handleTap(context, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Separate circular floating button with blue AI chatbot icon
            GestureDetector(
              onTap: () => _openChatbot(context),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: CustomPaint(
                      painter: _ChatbotBadgePainter(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryGreen : const Color(0xFF4A4A4A);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 25, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatbotBadgePainter extends CustomPainter {
  const _ChatbotBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()..color = AppColors.botNavy;

    // Robot antenna
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.16),
      Offset(size.width * 0.44, size.height * 0.32),
      Paint()
        ..color = AppColors.botNavy
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.14),
      2.8,
      navy,
    );

    // Side ear pads
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.50,
          size.width * 0.10,
          size.height * 0.24,
        ),
        const Radius.circular(4),
      ),
      navy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.70,
          size.height * 0.50,
          size.width * 0.10,
          size.height * 0.24,
        ),
        const Radius.circular(4),
      ),
      navy,
    );

    // Robot head shell
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.34,
        size.width * 0.56,
        size.height * 0.52,
      ),
      const Radius.circular(13),
    );
    canvas.drawRRect(headRect, navy);

    // White face screen inside head
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.23,
        size.height * 0.44,
        size.width * 0.42,
        size.height * 0.33,
      ),
      const Radius.circular(9),
    );
    canvas.drawRRect(faceRect, Paint()..color = Colors.white);

    // Eyes + smile
    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.56),
      2.2,
      navy,
    );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.56),
      2.2,
      navy,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.44, size.height * 0.63),
        width: size.width * 0.15,
        height: size.height * 0.10,
      ),
      0.1,
      2.9,
      false,
      Paint()
        ..color = AppColors.botNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Blue chat bubble with 3 white dots on top-right
    final bubbleCenter = Offset(size.width * 0.76, size.height * 0.30);
    final bubblePaint = Paint()..color = AppColors.botBubbleBlue;
    canvas.drawCircle(bubbleCenter, size.width * 0.21, bubblePaint);

    // Small tail on speech bubble
    final tail = Path()
      ..moveTo(bubbleCenter.dx - 6, bubbleCenter.dy + 5)
      ..lineTo(bubbleCenter.dx - 10, bubbleCenter.dy + 12)
      ..lineTo(bubbleCenter.dx - 1, bubbleCenter.dy + 8)
      ..close();
    canvas.drawPath(tail, bubblePaint);

    final dotPaint = Paint()..color = Colors.white;
    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(
        Offset(bubbleCenter.dx + i * 4.2, bubbleCenter.dy),
        1.4,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
