// Widget tests for the Connect application.
// These tests verify the functionality of Connect app widgets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connect/main.dart';
import 'package:connect/core/constants/app_constants.dart';
import 'package:connect/core/theme/app_theme.dart';

void main() {
  group('Connect App Tests', () {
    testWidgets('MyApp creates MaterialApp with correct configuration', (WidgetTester tester) async {
      // Build MyApp widget
      await tester.pumpWidget(const MyApp());

      // Verify that a MaterialApp is created
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify that the app has the correct title
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals(AppConstants.appTitle));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('App uses correct theme', (WidgetTester tester) async {
      // Build MyApp widget
      await tester.pumpWidget(const MyApp());

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify that the app uses AppTheme.lightTheme
      expect(materialApp.theme, equals(AppTheme.lightTheme));
    });

    testWidgets('IntroScreen is set as home', (WidgetTester tester) async {
      // Build MyApp widget
      await tester.pumpWidget(const MyApp());

      // Wait for initial frame
      await tester.pumpAndSettle();

      // Verify that IntroScreen-related elements are present
      // Look for "Connect with Trusted Professionals" or other intro text
      expect(
        find.textContaining('Connect with', findRichText: true),
        findsWidgets,
      );
    });

    test('AppConstants contains expected values', () {
      // Verify app constants
      expect(AppConstants.appName, equals('Connect'));
      expect(AppConstants.appTitle, equals('Connect'));
      expect(AppConstants.notificationChannelId, equals('high_importance_channel'));
      expect(AppConstants.envFileName, equals('.env'));
    });

    test('AppTheme provides light theme', () {
      // Verify that AppTheme provides a light theme
      final theme = AppTheme.lightTheme;
      expect(theme, isNotNull);
      expect(theme, isA<ThemeData>());
    });
  });
}
