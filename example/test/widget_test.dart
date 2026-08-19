// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_app_tour_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the tour example workspace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TourExampleApp());

    expect(find.text('Good morning, Alex'), findsOneWidget);
    expect(find.text('Start product tour'), findsOneWidget);
    expect(find.byTooltip('Search'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsOneWidget);
    expect(find.byTooltip('Open navigation'), findsOneWidget);
  });

  testWidgets('opens the navigation drawer', (WidgetTester tester) async {
    await tester.pumpWidget(const TourExampleApp());
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('starts the guided tour', (WidgetTester tester) async {
    await tester.pumpWidget(const TourExampleApp());
    await tester.tap(find.text('Start product tour'));
    await tester.pumpAndSettle();

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('opens the drawer from its guided tour step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TourExampleApp());
    await tester.tap(find.text('Start product tour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('Projects'), findsWidgets);
  });
}
