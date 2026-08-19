# flutter_app_tour

A lightweight Flutter package for creating guided onboarding and feature tours in your app.

This package helps you highlight important UI elements, explain features, and walk users through product flows with a clean overlay and simple API.

## Features

- Highlight target widgets with `TourTarget`
- Build multi-step onboarding flows with `TourController` and `TourStep`
- Position tooltips dynamically using `TooltipPosition`
- Control step animations and flow behavior
- Keep tours persistent with built-in `SharedPreferences` helpers
- Works with standard Flutter widgets and `GlobalKey`-based targets

## Installation

Add the package to your project:

```yaml
dependencies:
  flutter_app_tour: ^0.0.2
```

Then install dependencies:

```bash
flutter pub get
```

## Basic usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_app_tour/flutter_app_tour.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final searchKey = GlobalKey();
  final profileKey = GlobalKey();

  final controller = TourController(
    steps: [
      TourStep(
        id: TourId('search'),
        targetKey: searchKey,
        title: 'Search',
        description: 'Find anything quickly from the main app toolbar.',
      ),
      TourStep(
        id: TourId('profile'),
        targetKey: profileKey,
        title: 'Profile',
        description: 'Manage your account details and preferences here.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TourScope(
        controller: controller,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('My App'),
            actions: [
              TourTarget(
                id: TourId('search'),
                controller: controller,
                targetKey: searchKey,
                child: const Icon(Icons.search),
              ),
              TourTarget(
                id: TourId('profile'),
                controller: controller,
                targetKey: profileKey,
                child: const CircleAvatar(child: Icon(Icons.person)),
              ),
            ],
          ),
          body: const Center(child: Text('Welcome!')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: controller.start,
            label: const Text('Start tour'),
          ),
        ),
      ),
    );
  }
}
```

## Step customization

You can customize each step individually with additional options such as tooltip placement and animation.

```dart
final controller = TourController(
  steps: [
    TourStep(
      id: TourId('save'),
      targetKey: saveKey,
      title: 'Save your work',
      description: 'Tap here when you are ready to save your progress.',
      tooltipPosition: TooltipPosition.bottom,
      animation: TourAnimation.pulse,
    ),
  ],
);
```

## Persistence

You can check whether a user has already completed a tour and skip showing it again:

```dart
final hasSeenOnboarding = await TourController.hasSeenTour('onboarding-v1');

if (!hasSeenOnboarding) {
  await controller.start();
  await TourController.markTourAsSeen('onboarding-v1');
}
```

## Notes

- `TourTarget` must wrap the widget that should be highlighted.
- Each `TourStep` needs a unique `TourId` and its matching `GlobalKey`.
- `TourScope` must wrap the screen or page where the tour is displayed.
- Call `controller.start()` to begin the tour, and `controller.next()`, `controller.previous()`, or `controller.skip()` to navigate through steps.

For a working example, see the example app included in this package.

## License

This package is available under the MIT license.
