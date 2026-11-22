import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/analytics_item.dart';
import '../models/clothing_item.dart';
import '../models/outfit_recommendation.dart';
import 'mock_data.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static String get serverOrigin {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String get baseUrl => '$serverOrigin/api';

  static String resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    return '$serverOrigin$rawUrl';
  }

  static const Duration _timeout = Duration(milliseconds: 2200);

  String? _authToken;
  String? get authToken => _authToken;

  void setToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers({bool jsonContent = true}) {
    final headers = <String, String>{};
    if (jsonContent) {
      headers['Content-Type'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  String _formatUsername(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return '@user';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? email,
  }) async {
    final formatted = _formatUsername(username);
    final cleanEmail = (email == null || email.trim().isEmpty)
        ? 'hello@reallygreatsite.com'
        : email.trim();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers(),
            body: jsonEncode({
              'username': formatted,
              'password': password,
              'email': cleanEmail,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _authToken = data['token'] as String?;
        return data;
      }

      if (res.body.isNotEmpty) {
        final err = jsonDecode(res.body) as Map<String, dynamic>;
        throw AuthException(err['detail']?.toString() ?? 'Registration failed.');
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      // Offline fallback when backend server is not running
    }

    _authToken = 'offline-demo-jwt-token';
    return {
      'token': _authToken,
      'username': formatted,
      'email': cleanEmail,
      'phone': '+123-456-7890',
      'address': '123 Anywhere St., Any City, ST 12345',
    };
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final formatted = _formatUsername(username);

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers(),
            body: jsonEncode({'username': formatted, 'password': password}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _authToken = data['token'] as String?;
        return data;
      }

      if (res.statusCode == 401 && res.body.isNotEmpty) {
        final err = jsonDecode(res.body) as Map<String, dynamic>;
        throw AuthException(err['detail']?.toString() ?? 'Invalid credentials.');
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      // Fall back to local login if Python server isn't running
    }

    _authToken = 'offline-demo-jwt-token';
    return {
      'token': _authToken,
      'username': formatted,
      'email': 'hello@reallygreatsite.com',
      'phone': '+123-456-7890',
      'address': '123 Anywhere St., Any City, ST 12345',
    };
  }

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    if (_authToken == null) return null;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/auth/me'), headers: _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> updateProfile({
    String? username,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/auth/me'),
            headers: _headers(),
            body: jsonEncode({
              'username': ?username,
              'email': ?email,
              'phone': ?phone,
              'address': ?address,
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> fetchLiveWeather({bool refresh = false}) async {
    try {
      final uri = Uri.parse('$baseUrl/weather').replace(
        queryParameters: {'refresh': refresh.toString()},
      );
      final res = await http.get(uri, headers: _headers()).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['label'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<List<ClothingItem>> fetchClothes() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/clothes'), headers: _headers())
          .timeout(_timeout);
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
    Uint8List? imageBytes,
    required int fallbackId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/clothes'),
            headers: _headers(),
            body: jsonEncode({
              'name': name,
              'color': color,
              'tags': tags,
              'image_key': imageKey,
              if (imageBytes != null) 'image_base64': base64Encode(imageBytes),
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return ClothingItem.fromJson(data).copyWith(
          localImageBytes: imageBytes,
        );
      }
    } catch (_) {
      // Fall through to local item creation when offline
    }

    return ClothingItem(
      id: fallbackId,
      name: name,
      category: _inferCategory(name, tags),
      color: color,
      tags: tags,
      imageKey: imageKey,
      localImageBytes: imageBytes,
      isFavorite: false,
    );
  }

  Future<ClothingItem?> toggleFavorite(int itemId) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/clothes/$itemId/favorite'),
            headers: _headers(),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ClothingItem.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Handled optimistically in state
    }
    return null;
  }

  Future<OutfitRecommendation> fetchRecommendations({
    String? weatherOverride,
    required String plan,
    required String stylePref,
    required int localClothCount,
  }) async {
    try {
      final queryParams = <String, String>{
        'plan': plan,
        'style_pref': stylePref,
      };
      if (weatherOverride != null && weatherOverride.trim().isNotEmpty) {
        queryParams['weather'] = weatherOverride;
      }

      final uri = Uri.parse('$baseUrl/recommendations').replace(
        queryParameters: queryParams,
      );
      final res = await http.get(uri, headers: _headers()).timeout(_timeout);
      if (res.statusCode == 200) {
        return OutfitRecommendation.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Offline recommendation fallback
    }
    return MockData.buildOfflineRecommendation(
      weather: weatherOverride ?? 'Rainy 6°C',
      plan: plan,
      stylePref: stylePref,
      clothCount: localClothCount,
    );
  }

  Future<WardrobeAnalytics> fetchAnalytics() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/analytics'), headers: _headers())
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return WardrobeAnalytics.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
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
            headers: _headers(),
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
