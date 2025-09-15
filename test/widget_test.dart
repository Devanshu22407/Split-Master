// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dartpadcode/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<ChangeNotifier>>[
          ChangeNotifierProvider<AuthManager>(
            create: (BuildContext context) => AuthManager(),
          ),
          ChangeNotifierProvider<AppConfig>(
            create: (BuildContext context) => AppConfig(),
          ),
          ChangeNotifierProvider<ExpenseManager>(
            create: (BuildContext context) => ExpenseManager(),
          ),
        ],
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            home: const AuthWrapper(),
          );
        },
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
