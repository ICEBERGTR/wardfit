import 'dart:typed_data';
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

  String? get authToken => _api.authToken;
  bool get isAuthenticated => _api.authToken != null;

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
  String? _manualWeatherOverride;

  void setTab(int index) {
    if (currentTabIndex != index) {
      currentTabIndex = index;
      notifyListeners();
    }
  }

  void _applyUserMap(Map<String, dynamic> data) {
    final userObj = (data['user'] as Map<String, dynamic>?) ?? data;
    username = userObj['username'] as String? ?? username;
    email = userObj['email'] as String? ?? email;
    phone = userObj['phone'] as String? ?? phone;
    address = userObj['address'] as String? ?? address;
  }

  Future<void> signIn(String rawUsername, String password) async {
    final data = await _api.login(rawUsername, password);
    _applyUserMap(data);
    _manualWeatherOverride = null;
    await refreshDashboard();
  }

  Future<void> registerAccount({
    required String rawUsername,
    required String password,
    required String rawEmail,
  }) async {
    final data = await _api.register(
      username: rawUsername,
      password: password,
      email: rawEmail,
    );
    _applyUserMap(data);
    _manualWeatherOverride = null;
    await refreshDashboard();
  }

  void signOut() {
    _api.setToken(null);
    currentTabIndex = 0;
    selectedPlan = '';
    _manualWeatherOverride = null;
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    final results = await Future.wait([
      _api.fetchClothes(),
      _api.fetchAnalytics(),
      _api.fetchCurrentUser(),
    ]);

    clothes = results[0] as List<ClothingItem>;
    analytics = results[1] as WardrobeAnalytics;
    final me = results[2] as Map<String, dynamic>?;
    if (me != null) {
      _applyUserMap(me);
    }

    recommendation = await _api.fetchRecommendations(
      weatherOverride: _manualWeatherOverride,
      plan: _planSlug(selectedPlan),
      stylePref: selectedStyleChoice.contains('change') ? 'change' : 'keep',
      localClothCount: clothes.length,
    );
    weather = recommendation.weather;
    notifyListeners();
  }

  Future<void> updatePlan(String planOption) async {
    selectedPlan = planOption;
    recommendation = await _api.fetchRecommendations(
      weatherOverride: _manualWeatherOverride,
      plan: _planSlug(planOption),
      stylePref: selectedStyleChoice.contains('change') ? 'change' : 'keep',
      localClothCount: clothes.length,
    );
    weather = recommendation.weather;
    notifyListeners();
  }

  Future<void> updateStylePreference(String option) async {
    selectedStyleChoice = option;
    recommendation = await _api.fetchRecommendations(
      weatherOverride: _manualWeatherOverride,
      plan: _planSlug(selectedPlan),
      stylePref: option.contains('change') ? 'change' : 'keep',
      localClothCount: clothes.length,
    );
    weather = recommendation.weather;
    notifyListeners();
  }

  Future<void> cycleWeather() async {
    // First try refreshing live Open-Meteo weather; if user taps repeatedly, cycle presets
    const options = ['Rainy 6°C', 'Clear 19°C', 'Cloudy 11°C', 'Snowy -2°C'];
    final currentIdx = options.indexOf(weather);
    final nextWeather = options[(currentIdx + 1) % options.length];
    _manualWeatherOverride = nextWeather;
    weather = nextWeather;

    recommendation = await _api.fetchRecommendations(
      weatherOverride: _manualWeatherOverride,
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
    Uint8List? imageBytes,
  }) async {
    final created = await _api.addClothingItem(
      name: name,
      color: color,
      tags: tags,
      imageKey: imageKey,
      imageBytes: imageBytes,
      fallbackId: DateTime.now().millisecondsSinceEpoch,
    );
    clothes = [created, ...clothes];
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

    final current = clothes[idx];
    clothes[idx] = current.copyWith(isFavorite: !current.isFavorite);
    notifyListeners();

    final serverUpdated = await _api.toggleFavorite(id);
    if (serverUpdated != null) {
      final latestIdx = clothes.indexWhere((c) => c.id == id);
      if (latestIdx != -1) {
        clothes[latestIdx] = serverUpdated.copyWith(
          localImageBytes: current.localImageBytes,
        );
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

  Future<void> updateProfileField({
    String? newUsername,
    String? newEmail,
    String? newPhone,
    String? newAddress,
  }) async {
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

    final updated = await _api.updateProfile(
      username: username,
      email: email,
      phone: phone,
      address: address,
    );
    if (updated != null) {
      _applyUserMap(updated);
      notifyListeners();
    }
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
