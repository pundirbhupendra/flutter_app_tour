// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

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
  });

  testWidgets('starts the guided tour', (WidgetTester tester) async {
    await tester.pumpWidget(const TourExampleApp());
    await tester.tap(find.text('Start product tour'));
    await tester.pumpAndSettle();

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
