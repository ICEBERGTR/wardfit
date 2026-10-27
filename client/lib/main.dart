import 'package:flutter/material.dart';

import 'screens/add_clothes_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'services/wardrobe_state.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_shell.dart';

void main() {
  runApp(const WardFitApp());
}

class WardFitApp extends StatefulWidget {
  const WardFitApp({super.key});

  @override
  State<WardFitApp> createState() => _WardFitAppState();
}

class _WardFitAppState extends State<WardFitApp> {
  final WardrobeState _wardrobeState = WardrobeState();

  @override
  void dispose() {
    _wardrobeState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WardrobeScope(
      state: _wardrobeState,
      child: ListenableBuilder(
        listenable: _wardrobeState,
        builder: (context, _) {
          return MaterialApp(
            title: 'WardFit',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode:
                _wardrobeState.darkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/login',
            routes: {
              '/login': (_) => const LoginScreen(),
              '/main': (_) => const MainShellScreen(),
              '/calendar': (_) => const CalendarScreen(),
              '/catalog': (_) => const CatalogScreen(),
              '/add-clothes': (_) => const AddClothesScreen(),
              '/loading': (_) => LoadingScreen(
                    displayUsername: _wardrobeState.username,
                    nextRouteName: '/main',
                  ),
            },
          );
        },
      ),
    );
  }
}

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _tabs = [
    HomeScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = WardrobeScope.of(context);
    final idx = state.currentTabIndex;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: idx,
          children: _tabs,
        ),
      ),
      // Screen 5 (Profile & Settings) uses its own Back header and Sign Out footer
      bottomNavigationBar: idx == 2
          ? null
          : WardFitBottomBar(
              activeIndex: idx,
              onTabSelected: state.setTab,
            ),
    );
  }
}
