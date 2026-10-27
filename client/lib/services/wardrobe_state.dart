import 'package:flutter/material.dart';

import '../models/analytics_item.dart';
import '../models/clothing_item.dart';
import '../models/outfit_recommendation.dart';
import 'api_service.dart';
import 'mock_data.dart';

class WardrobeState extends ChangeNotifier {
  final ApiService _api = ApiService();

  // User profile & settings state
  String username = '@user';
  String email = 'hello@reallygreatsite.com';
  String phone = '+123-456-7890';
  String address = '123 Anywhere St., Any City, ST 12345';
  String language = 'English';
  bool silentMode = false;
  bool darkMode = false;

  // Navigation tab index on main shell (0: Home, 1: Search, 2: Settings)
  int currentTabIndex = 0;

  // Wardrobe data
  List<ClothingItem> clothes = List<ClothingItem>.from(MockData.initialClothes);
  OutfitRecommendation recommendation = MockData.defaultRecommendation;
  WardrobeAnalytics analytics = MockData.defaultAnalytics;

  // Interactive suggestion selections (Screen 3)
  String selectedPlan = '';
  String selectedStyleChoice = "I'll keep my dress style the same.";
  String weather = 'Rainy 6°C';

  void setTab(int index) {
    if (currentTabIndex != index) {
      currentTabIndex = index;
      notifyListeners();
    }
  }

  Future<void> signIn(String rawUsername, String password) async {
    username = await _api.login(rawUsername, password);
    await refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    final results = await Future.wait([
      _api.fetchClothes(),
      _api.fetchAnalytics(),
    ]);

    clothes = results[0] as List<ClothingItem>;
    analytics = results[1] as WardrobeAnalytics;

    recommendation = await _api.fetchRecommendations(
      weather: weather,
      plan: _planSlug(selectedPlan),
      stylePref: selectedStyleChoice.contains('change') ? 'change' : 'keep',
      localClothCount: clothes.length,
    );
    notifyListeners();
  }

  Future<void> updatePlan(String planOption) async {
    selectedPlan = planOption;
    recommendation = await _api.fetchRecommendations(
      weather: weather,
      plan: _planSlug(planOption),
      stylePref: selectedStyleChoice.contains('change') ? 'change' : 'keep',
      localClothCount: clothes.length,
    );
    notifyListeners();
  }

  Future<void> updateStylePreference(String option) async {
    selectedStyleChoice = option;
    recommendation = await _api.fetchRecommendations(
      weather: weather,
      plan: _planSlug(selectedPlan),
      stylePref: option.contains('change') ? 'change' : 'keep',
      localClothCount: clothes.length,
    );
    notifyListeners();
  }

  Future<void> cycleWeather() async {
    const options = ['Rainy 6°C', 'Sunny 18°C', 'Cloudy 11°C', 'Snowy -2°C'];
    final nextIdx = (options.indexOf(weather) + 1) % options.length;
    weather = options[nextIdx];
    recommendation = await _api.fetchRecommendations(
      weather: weather,
      plan: _planSlug(selectedPlan),
      stylePref: selectedStyleChoice.contains('change') ? 'change' : 'keep',
      localClothCount: clothes.length,
    );
    notifyListeners();
  }

  Future<ClothingItem> addClothes({
    required String name,
    required String color,
    required String tags,
    required String imageKey,
  }) async {
    final created = await _api.addClothingItem(
      name: name,
      color: color,
      tags: tags,
      imageKey: imageKey,
      fallbackId: DateTime.now().millisecondsSinceEpoch,
    );
    clothes = [created, ...clothes];
    // Refresh style count when closet grows
    recommendation = OutfitRecommendation(
      todaysOutfit: recommendation.todaysOutfit,
      weather: recommendation.weather,
      stylesRemaining: recommendation.stylesRemaining + 1,
      monthlyStylesTried: recommendation.monthlyStylesTried,
      tip: recommendation.tip,
      schedule: recommendation.schedule,
    );
    notifyListeners();
    return created;
  }

  Future<void> toggleFavorite(int id) async {
    final idx = clothes.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    // Optimistic UI update
    final current = clothes[idx];
    clothes[idx] = current.copyWith(isFavorite: !current.isFavorite);
    notifyListeners();

    final serverUpdated = await _api.toggleFavorite(id);
    if (serverUpdated != null) {
      final latestIdx = clothes.indexWhere((c) => c.id == id);
      if (latestIdx != -1) {
        clothes[latestIdx] = serverUpdated;
        notifyListeners();
      }
    }
  }

  void toggleSilentMode(bool val) {
    silentMode = val;
    notifyListeners();
  }

  void toggleDarkMode(bool val) {
    darkMode = val;
    notifyListeners();
  }

  void updateProfileField({
    String? newUsername,
    String? newEmail,
    String? newPhone,
    String? newAddress,
  }) {
    if (newUsername != null && newUsername.trim().isNotEmpty) {
      final raw = newUsername.trim();
      username = raw.startsWith('@') ? raw : '@$raw';
    }
    if (newEmail != null && newEmail.trim().isNotEmpty) email = newEmail.trim();
    if (newPhone != null && newPhone.trim().isNotEmpty) phone = newPhone.trim();
    if (newAddress != null && newAddress.trim().isNotEmpty) {
      address = newAddress.trim();
    }
    notifyListeners();
  }

  Future<String> askStylist(String prompt) {
    return _api.sendChatMessage(prompt, weather);
  }

  String _planSlug(String planText) {
    final lower = planText.toLowerCase();
    if (lower.contains('workplace')) return 'workplace';
    if (lower.contains('free')) return 'free';
    if (lower.contains('new')) return 'new';
    return 'default';
  }
}

// InheritedNotifier wrapper so any screen can read/listen to WardrobeState cleanly
class WardrobeScope extends InheritedNotifier<WardrobeState> {
  const WardrobeScope({
    super.key,
    required WardrobeState state,
    required super.child,
  }) : super(notifier: state);

  static WardrobeState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WardrobeScope>();
    assert(scope != null, 'WardrobeScope not found in widget tree');
    return scope!.notifier!;
  }
}
