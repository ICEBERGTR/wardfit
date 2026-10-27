import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wardfit/main.dart';

void main() {
  testWidgets('Full WardFit flow across screens renders without errors', (
    tester,
  ) async {
    // Use generous mobile viewport so wide test-font glyphs fit comfortably
    tester.view.physicalSize = const Size(480, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WardFitApp());

    // Screen 1: Login Screen
    expect(find.text('WARDFIT'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '@ayberk');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Screen 6: Loading / Splash Screen
    expect(find.text('Hello @ayberk'), findsOneWidget);
    expect(find.text('How are you today?'), findsOneWidget);

    // Advance past 1.35s splash transition to land on Home Dashboard
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Screen 2: Home Dashboard
    expect(find.text('Hi @ayberk'), findsOneWidget);
    expect(find.text('WardFIT360 Analytics'), findsOneWidget);
    expect(
      find.text('Gryphon Sweatshirt + black jeans'),
      findsOneWidget,
    );

    // Tap today's outfit -> Screen 4: Today's Wardrobe / Calendar View
    await tester.tap(find.text("today's outfit"));
    await tester.pumpAndSettle();
    expect(find.text('January 2024'), findsOneWidget);
    expect(find.text('Blue shirt + fabric trousers'), findsOneWidget);

    // Navigate back to Home
    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left_rounded));
    await tester.pumpAndSettle();

    // Tap styles remaining -> Screen 7: My Clothes Catalog
    await tester.tap(find.text('number of clothing styles remaining'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Clothes'), findsOneWidget);
    expect(find.text('Parachute jacket'), findsOneWidget);

    // Tap Add New Clothes -> Screen 8: Add New Clothes Form
    await tester.tap(find.text('Add New Clothes'));
    await tester.pumpAndSettle();
    expect(find.text('RETAKE PIC'), findsOneWidget);
    expect(find.text('SAVE'), findsOneWidget);

    // Switch to Search tab (Screen 3) via bottom pill bar
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text("What's your plan for tomorrow?"), findsOneWidget);

    // Switch to Settings tab (Screen 5) via bottom pill bar
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Silent Mode'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });
}
