import 'package:flutter/material.dart';

class AnalyticsSeriesItem {
  final String label;
  final String colorHex;
  final int jan;
  final int feb;
  final int mar;

  const AnalyticsSeriesItem({
    required this.label,
    required this.colorHex,
    required this.jan,
    required this.feb,
    required this.mar,
  });

  Color get color {
    final cleaned = colorHex.replaceAll('#', '');
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    return parsed != null ? Color(parsed) : Colors.blue;
  }

  factory AnalyticsSeriesItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsSeriesItem(
      label: json['label'] as String? ?? '',
      colorHex: json['color_hex'] as String? ?? '#29B6F6',
      jan: json['jan'] as int? ?? 0,
      feb: json['feb'] as int? ?? 0,
      mar: json['mar'] as int? ?? 0,
    );
  }
}

class WardrobeAnalytics {
  final List<String> months;
  final int maxY;
  final int monthlyStylesTried;
  final List<AnalyticsSeriesItem> series;

  const WardrobeAnalytics({
    required this.months,
    required this.maxY,
    required this.monthlyStylesTried,
    required this.series,
  });

  factory WardrobeAnalytics.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'] as List<dynamic>? ?? [];
    final rawMonths = json['months'] as List<dynamic>? ?? ['JAN', 'FEB', 'MAR'];
    return WardrobeAnalytics(
      months: rawMonths.map((m) => m.toString()).toList(),
      maxY: json['max_y'] as int? ?? 35,
      monthlyStylesTried: json['monthly_styles_tried'] as int? ?? 28,
      series: rawSeries
          .map((e) => AnalyticsSeriesItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
