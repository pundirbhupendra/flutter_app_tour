import 'package:flutter/material.dart';
import 'package:flutter_app_tour/flutter_app_tour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TourController', () {
    late List<GlobalKey> keys;
    late List<TourStep> steps;
    late TourController controller;

    setUp(() {
      keys = List<GlobalKey>.generate(3, (_) => GlobalKey());
      steps = List<TourStep>.generate(
        3,
        (index) => TourStep(
          id: TourId('step-$index'),
          targetKey: keys[index],
          title: 'Title $index',
          description: 'Description $index',
        ),
      );
      controller = TourController(steps: steps);
    });

    tearDown(() => controller.dispose());

    testWidgets('starts, advances, goes back, skips, and finishes', (
      tester,
    ) async {
      await _pumpTargets(tester, controller, steps);

      await controller.start();
      expect(controller.isActive, isTrue);
      expect(controller.currentIndex, 0);
      expect(controller.isFirstStep, isTrue);

      final next = controller.next();
      await tester.pump(TourController.transitionDuration);
      await next;
      expect(controller.currentIndex, 1);
      expect(controller.currentStep, steps[1]);

      final previous = controller.previous();
      await tester.pump(TourController.transitionDuration);
      await previous;
      expect(controller.currentIndex, 0);

      controller.skip();
      expect(controller.isActive, isFalse);

      await controller.start();
      controller.finish();
      expect(controller.isActive, isFalse);
    });

    testWidgets('sequences through three steps and finishes after the last', (
      tester,
    ) async {
      await _pumpTargets(tester, controller, steps);
      await controller.start();

      for (var index = 1; index < steps.length; index++) {
        final next = controller.next();
        await tester.pump(TourController.transitionDuration);
        await next;
        expect(controller.currentIndex, index);
        expect(controller.currentStep?.id.value, 'step-$index');
      }

      final complete = controller.next();
      await tester.pump(TourController.transitionDuration);
      await complete;
      expect(controller.isActive, isFalse);
    });

    testWidgets(
      'renders the active step title and description in the overlay',
      (tester) async {
        await _pumpTargets(tester, controller, steps);
        await controller.start();
        await tester.pumpAndSettle();
        expect(find.text('Title 0'), findsOneWidget);
        expect(find.text('Description 0'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);

        await tester.tap(find.text('Next'));
        await tester.pump(TourController.transitionDuration);
        await tester.pumpAndSettle();
        expect(find.text('Title 1'), findsOneWidget);
        expect(find.text('Description 1'), findsOneWidget);
      },
    );
  });

  test('persists seen state using mocked SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await TourController.hasSeenTour('onboarding-v1'), isFalse);

    await TourController.markTourAsSeen('onboarding-v1');

    expect(await TourController.hasSeenTour('onboarding-v1'), isTrue);
  });

  testWidgets('handles target removal during widget dispose without throwing', (
    tester,
  ) async {
    final key = GlobalKey();
    final step = TourStep(
      id: TourId('remove-test'),
      targetKey: key,
      title: 'Remove',
      description: 'Remove desc',
    );
    final controller = TourController(steps: [step]);

    // Host widget that can remove the TourTarget on demand.
    final hostKey = GlobalKey<_TestHostState>();

    await tester.pumpWidget(
      MaterialApp(
        home: TestHost(key: hostKey, controller: controller, step: step),
      ),
    );

    await controller.start();
    await tester.pumpAndSettle();
    expect(controller.isActive, isTrue);

    // Remove the target from the tree which triggers dispose/unregister.
    hostKey.currentState!.removeTarget();
    await tester.pumpAndSettle();

    // Controller should have advanced or finished without throwing.
    expect(controller.isActive, isFalse);
    controller.dispose();
  });

  testWidgets('uses custom tooltipBuilder when provided', (tester) async {
    final key = GlobalKey();
    final step = TourStep(
      id: TourId('custom-tip'),
      targetKey: key,
      title: 'Tip',
      description: 'Tip desc',
    );
    final controller = TourController(steps: [step]);

    await tester.pumpWidget(
      MaterialApp(
        home: TourScope(
          controller: controller,
          tooltipBuilder: (ctx, s, c, rect, size, theme) =>
              const Text('CustomTip'),
          child: Scaffold(
            body: TourTarget(
              id: step.id,
              controller: controller,
              targetKey: step.targetKey,
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      ),
    );

    await controller.start();
    await tester.pumpAndSettle();

    expect(find.text('CustomTip'), findsOneWidget);
    controller.dispose();
  });
}

class TestHost extends StatefulWidget {
  const TestHost({super.key, required this.controller, required this.step});

  final TourController controller;
  final TourStep step;

  @override
  _TestHostState createState() => _TestHostState();
}

class _TestHostState extends State<TestHost> {
  bool _show = true;

  void removeTarget() => setState(() => _show = false);

  @override
  Widget build(BuildContext context) {
    return TourScope(
      controller: widget.controller,
      child: Scaffold(
        body: Column(
          children: [
            if (_show)
              TourTarget(
                id: widget.step.id,
                controller: widget.controller,
                targetKey: widget.step.targetKey,
                child: const SizedBox(width: 10, height: 10),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pumpTargets(
  WidgetTester tester,
  TourController controller,
  List<TourStep> steps,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: TourScope(
        controller: controller,
        child: Scaffold(
          body: Column(
            children: [
              for (final step in steps)
                TourTarget(
                  id: step.id,
                  controller: controller,
                  targetKey: step.targetKey,
                  child: Text(step.id.toString()),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
