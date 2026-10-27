import 'package:flutter/material.dart';
import '../models/analytics_item.dart';
import '../services/wardrobe_state.dart';
import '../theme/app_theme.dart';
import '../widgets/clothing_illustration.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = WardrobeScope.of(context);
    final rec = state.recommendation;
    final analytics = state.analytics;

    return Column(
      children: [
        // Top header bar
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/catalog'),
                    child: const Text(
                      'My Clothes',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/catalog'),
                    child: Row(
                      children: [
                        Text(
                          'Hi ${state.username}',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.limeBright,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            size: 17,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Today's pick (${rec.weather}): ${rec.todaysOutfit}",
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 30,
                      color: AppColors.textDark,
                    ),
                    Positioned(
                      right: 3,
                      top: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable dashboard content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Today's outfit card -> opens Screen 4 (Calendar)
                _SummaryCard(
                  subtitle: "today's outfit",
                  title: rec.todaysOutfit,
                  iconType: 'hanger',
                  onTap: () => Navigator.pushNamed(context, '/calendar'),
                ),
                const SizedBox(height: 12),

                // 2. Weather card -> cycles weather & updates outfit
                _SummaryCard(
                  subtitle: 'Weather',
                  title: rec.weather,
                  iconType: 'water',
                  onTap: () => state.cycleWeather(),
                ),
                const SizedBox(height: 12),

                // 3. Remaining clothing styles -> opens Screen 7 (Catalog)
                _SummaryCard(
                  subtitle: 'number of clothing styles remaining',
                  title: '${rec.stylesRemaining}',
                  iconType: 'stack',
                  onTap: () => Navigator.pushNamed(context, '/catalog'),
                ),
                const SizedBox(height: 18),

                // WardFIT360 Analytics Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WardFIT360 Analytics',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 10-item legend matching the chart bars
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 5,
                          children: analytics.series
                              .map(
                                (item) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: item.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 7.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Grouped bar chart across JAN, FEB, MAR
                      SizedBox(
                        height: 175,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _WardFitAnalyticsChartPainter(
                            analytics: analytics,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tips section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tips',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(rec.tip.message),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Energy Tip Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rec.tip.category,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  rec.tip.date,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              rec.tip.message,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String subtitle;
  final String title;
  final String iconType;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.subtitle,
    required this.title,
    required this.iconType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SummaryOutlineIcon(type: iconType),
            ],
          ),
        ),
      ),
    );
  }
}

class _WardFitAnalyticsChartPainter extends CustomPainter {
  final WardrobeAnalytics analytics;

  const _WardFitAnalyticsChartPainter({required this.analytics});

  @override
  void paint(Canvas canvas, Size size) {
    const leftAxisWidth = 22.0;
    const bottomAxisHeight = 18.0;
    final chartWidth = size.width - leftAxisWidth;
    final chartHeight = size.height - bottomAxisHeight;
    final maxY = analytics.maxY.toDouble();

    final gridPaint = Paint()
      ..color = const Color(0xFFEAEAEA)
      ..strokeWidth = 1;

    // Draw Y-axis ticks (0 to 35 in steps of 5) and horizontal grid lines
    for (int tick = 0; tick <= analytics.maxY; tick += 5) {
      final ratio = tick / maxY;
      final y = chartHeight - (ratio * chartHeight);

      canvas.drawLine(Offset(leftAxisWidth, y), Offset(size.width, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$tick',
          style: const TextStyle(
            fontSize: 7.5,
            color: AppColors.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftAxisWidth - tp.width - 5, y - tp.height / 2));
    }

    if (analytics.series.isEmpty) return;

    final groupCount = analytics.months.length;
    final groupWidth = chartWidth / groupCount;
    final barCount = analytics.series.length;

    for (int g = 0; g < groupCount; g++) {
      final groupStart = leftAxisWidth + g * groupWidth;
      final innerPadding = groupWidth * 0.08;
      final usableWidth = groupWidth - innerPadding * 2;
      final slotWidth = usableWidth / barCount;
      final barWidth = (slotWidth * 0.78).clamp(3.0, 9.0);

      for (int i = 0; i < barCount; i++) {
        final item = analytics.series[i];
        final value = g == 0
            ? item.jan
            : g == 1
                ? item.feb
                : item.mar;
        final barHeight = (value / maxY) * chartHeight;
        final x = groupStart + innerPadding + i * slotWidth;
        final y = chartHeight - barHeight;

        final rrect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        );
        canvas.drawRRect(rrect, Paint()..color = item.color);
      }

      // Month label centered under group
      final monthPainter = TextPainter(
        text: TextSpan(
          text: analytics.months[g],
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      monthPainter.paint(
        canvas,
        Offset(
          groupStart + (groupWidth - monthPainter.width) / 2,
          chartHeight + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WardFitAnalyticsChartPainter oldDelegate) =>
      oldDelegate.analytics != analytics;
}
