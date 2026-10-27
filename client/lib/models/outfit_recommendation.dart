class DailyTip {
  final String category;
  final String date;
  final String message;

  const DailyTip({
    required this.category,
    required this.date,
    required this.message,
  });

  factory DailyTip.fromJson(Map<String, dynamic> json) {
    return DailyTip(
      category: json['category'] as String? ?? 'Energy',
      date: json['date'] as String? ?? 'Sat, 11 Jan',
      message: json['message'] as String? ??
          'wearing yellow this week will make you feel more energised!',
    );
  }
}

class ScheduleEvent {
  final String time;
  final String outfit;
  final String accent; // 'coral' or 'blue'
  final String topKey;
  final String bottomKey;

  const ScheduleEvent({
    required this.time,
    required this.outfit,
    required this.accent,
    required this.topKey,
    required this.bottomKey,
  });

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      time: json['time'] as String? ?? '10:00 AM',
      outfit: json['outfit'] as String? ?? '',
      accent: json['accent'] as String? ?? 'coral',
      topKey: json['top_key'] as String? ?? 'gryphon_sweatshirt',
      bottomKey: json['bottom_key'] as String? ?? 'black_jeans',
    );
  }
}

class OutfitRecommendation {
  final String todaysOutfit;
  final String weather;
  final int stylesRemaining;
  final int monthlyStylesTried;
  final DailyTip tip;
  final List<ScheduleEvent> schedule;

  const OutfitRecommendation({
    required this.todaysOutfit,
    required this.weather,
    required this.stylesRemaining,
    required this.monthlyStylesTried,
    required this.tip,
    required this.schedule,
  });

  factory OutfitRecommendation.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['schedule'] as List<dynamic>? ?? [];
    return OutfitRecommendation(
      todaysOutfit:
          json['todays_outfit'] as String? ?? 'Gryphon Sweatshirt + black jeans',
      weather: json['weather'] as String? ?? 'Rainy 6°C',
      stylesRemaining: json['styles_remaining'] as int? ?? 14,
      monthlyStylesTried: json['monthly_styles_tried'] as int? ?? 28,
      tip: DailyTip.fromJson(
          json['tip'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      schedule: rawSchedule
          .map((e) => ScheduleEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
