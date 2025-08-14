// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plantmeet/main.dart';
import 'package:plantmeet/services/app_state.dart';
import 'package:plantmeet/services/database_service.dart';
import 'package:plantmeet/services/database.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Create mock services for testing
    final database = AppDatabase();
    final databaseService = DatabaseService(database);
    final appState = AppState(databaseService: databaseService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => appState,
        child: const PlantMeetApp(hasSeenOnboarding: true),
      ),
    );

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
