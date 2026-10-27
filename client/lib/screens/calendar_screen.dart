import 'package:flutter/material.dart';
import '../models/outfit_recommendation.dart';
import '../services/wardrobe_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_shell.dart';
import '../widgets/clothing_illustration.dart';
import '../widgets/wardfit_logo.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _selectedDay = '18';

  static const List<Map<String, String>> _days = [
    {'day': '15', 'weekday': 'Thu'},
    {'day': '16', 'weekday': 'Fri'},
    {'day': '17', 'weekday': 'Sat'},
    {'day': '18', 'weekday': 'Sun'},
    {'day': '19', 'weekday': 'Mon'},
    {'day': '20', 'weekday': 'Tue'},
  ];

  static const List<String> _timelineHours = [
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 AM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final state = WardrobeScope.of(context);
    final scheduleMap = <String, ScheduleEvent>{
      for (final ev in state.recommendation.schedule) ev.time: ev,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const WardFitBottomBar(activeIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header with lime double-chevron, title, and user avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const Icon(
                            Icons.keyboard_double_arrow_left_rounded,
                            color: AppColors.limeAccent,
                            size: 42,
                          ),
                        ),
                        const Text(
                          "Today's\nWardrobe",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3E3A39),
                            height: 1.15,
                          ),
                        ),
                        const UserAvatarBadge(size: 46),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // Month / Weather header + sage calendar-check icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'January 2024',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3E3A39),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.recommendation.weather,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3E3A39),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: AppColors.sageCircle,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Horizontal day selector (15 Thu - 20 Tue)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _days.map((item) {
                        final day = item['day']!;
                        final weekday = item['weekday']!;
                        final selected = day == _selectedDay;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.coralPill
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF3E3A39),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  weekday,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: selected
                                        ? const Color(0xFF3E3A39)
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Orange separator line with circular end caps
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.timelineLine,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: AppColors.timelineLine,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.timelineLine,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Hourly timeline from 8:00 AM to 7:00 PM
                    ..._timelineHours.map((hour) {
                      final event = scheduleMap[hour];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 78,
                              child: Text(
                                hour,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF3E3A39),
                                ),
                              ),
                            ),
                            if (event != null)
                              Expanded(
                                child: Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: event.accent == 'coral'
                                        ? AppColors.coralPill
                                        : AppColors.bluePill,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      ClothingIllustration(
                                        imageKey: event.topKey,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          event.outfit,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2B2B2B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      ClothingIllustration(
                                        imageKey: event.bottomKey,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
