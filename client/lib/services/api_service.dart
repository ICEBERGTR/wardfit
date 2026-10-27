import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/analytics_item.dart';
import '../models/clothing_item.dart';
import '../models/outfit_recommendation.dart';
import 'mock_data.dart';

class ApiService {
  // Android emulator maps host localhost to 10.0.2.2
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static const Duration _timeout = Duration(milliseconds: 1800);

  Future<String> login(String username, String password) async {
    final formatted = username.trim().isEmpty
        ? '@user'
        : (username.trim().startsWith('@')
            ? username.trim()
            : '@${username.trim()}');

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': formatted, 'password': password}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['username'] as String? ?? formatted;
      }
    } catch (_) {
      // Fall back to local login if Python server isn't running
    }
    return formatted;
  }

  Future<List<ClothingItem>> fetchClothes() async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/clothes')).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawList = data['items'] as List<dynamic>? ?? [];
        return rawList
            .map((item) => ClothingItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Use starter mock catalog when offline
    }
    return List<ClothingItem>.from(MockData.initialClothes);
  }

  Future<ClothingItem> addClothingItem({
    required String name,
    required String color,
    required String tags,
    required String imageKey,
    required int fallbackId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/clothes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'color': color,
              'tags': tags,
              'image_key': imageKey,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return ClothingItem.fromJson(data);
      }
    } catch (_) {
      // Fall through to local item creation
    }

    return ClothingItem(
      id: fallbackId,
      name: name,
      category: _inferCategory(name, tags),
      color: color,
      tags: tags,
      imageKey: imageKey,
      isFavorite: false,
    );
  }

  Future<ClothingItem?> toggleFavorite(int itemId) async {
    try {
      final res = await http
          .patch(Uri.parse('$baseUrl/clothes/$itemId/favorite'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ClothingItem.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {
      // Handled optimistically in state
    }
    return null;
  }

  Future<OutfitRecommendation> fetchRecommendations({
    required String weather,
    required String plan,
    required String stylePref,
    required int localClothCount,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/recommendations').replace(
        queryParameters: {
          'weather': weather,
          'plan': plan,
          'style_pref': stylePref,
        },
      );
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        return OutfitRecommendation.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {
      // Offline recommendation fallback
    }
    return MockData.buildOfflineRecommendation(
      weather: weather,
      plan: plan,
      stylePref: stylePref,
      clothCount: localClothCount,
    );
  }

  Future<WardrobeAnalytics> fetchAnalytics() async {
    try {
      final res =
          await http.get(Uri.parse('$baseUrl/analytics')).timeout(_timeout);
      if (res.statusCode == 200) {
        return WardrobeAnalytics.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {
      // Offline analytics fallback
    }
    return MockData.defaultAnalytics;
  }

  Future<String> sendChatMessage(String message, String weather) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message, 'weather': weather}),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['reply'] as String? ?? '';
      }
    } catch (_) {
      // Local stylist fallback
    }

    final lower = message.toLowerCase();
    if (lower.contains('work') || lower.contains('office')) {
      return 'For tomorrow at work, try your Blue shirt + fabric trousers with the Parachute jacket.';
    }
    if (lower.contains('rain') || lower.contains('weather')) {
      return 'It is $weather right now. Gryphon Sweatshirt + black jeans with your Villa rain jacket is a solid pick.';
    }
    return 'I recommend your Gryphon Sweatshirt + black jeans for daytime, or yellow uspa shirt + blue jean if you want an energy boost!';
  }

  String _inferCategory(String name, String tags) {
    final combined = '$name $tags'.toLowerCase();
    if (combined.contains('jean') ||
        combined.contains('pant') ||
        combined.contains('trouser')) {
      return 'Pants';
    }
    if (combined.contains('shoe') ||
        combined.contains('nike') ||
        combined.contains('jordan')) {
      return 'Shoes';
    }
    if (combined.contains('shirt') ||
        combined.contains('sweat') ||
        combined.contains('sweater') ||
        combined.contains('hoodie')) {
      return 'Shirts';
    }
    return 'Outwear';
  }
}
