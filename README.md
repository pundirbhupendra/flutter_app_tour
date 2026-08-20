# flutter_app_tour

A lightweight, customizable guided-tour overlay for Flutter onboarding flows and feature discovery.

`flutter_app_tour` highlights real widgets in your app, positions a tooltip around each target, and provides simple step navigation without adding a state-management framework.

## Features

- Multi-step widget tours with previous, next, skip, and completion controls.
- Automatic scrolling and tooltip placement.
- Custom spotlight shapes, animations, themes, and tooltips.
- Optional persistence through `TourStorage`.

## Requirements

- Flutter `3.44.0` or later
- Dart `3.12.2` or later

## Installation

Add the latest version shown on pub.dev to your app's `pubspec.yaml`:

```yaml
dependencies:
  flutter_app_tour: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Quick start

Create a `GlobalKey` for each widget you want to highlight. Register the same key and `TourId` in both `TourStep` and `TourTarget`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_app_tour/flutter_app_tour.dart';

class TourHomePage extends StatefulWidget {
  const TourHomePage({super.key});

  @override
  State<TourHomePage> createState() => _TourHomePageState();
}

class _TourHomePageState extends State<TourHomePage> {
  final searchKey = GlobalKey();
  final profileKey = GlobalKey();

  late final controller = TourController(
    steps: [
      TourStep(
        id: TourId('search'),
        targetKey: searchKey,
        title: 'Search',
        description: 'Find projects, notes, and teammates quickly.',
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
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TourScope(
      controller: controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My App'),
          actions: [
            TourTarget(
              id: TourId('search'),
              controller: controller,
              targetKey: searchKey,
              child: IconButton(
                tooltip: 'Search',
                onPressed: () {},
                icon: const Icon(Icons.search),
              ),
            ),
            TourTarget(
              id: TourId('profile'),
              controller: controller,
              targetKey: profileKey,
              child: IconButton(
                tooltip: 'Profile',
                onPressed: () {},
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ),
          ],
        ),
        body: const Center(child: Text('Welcome!')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: controller.start,
          label: const Text('Start tour'),
        ),
      ),
    );
  }
}
```

`TourScope` must wrap the screen subtree containing the target widgets. A target must be mounted before its step can be shown.

## Customize steps

Customize tooltip placement, animation, spotlight shape, and scrolling per step:

```dart
TourStep(
  id: TourId('insights'),
  targetKey: insightsKey,
  title: 'Weekly insights',
  description: 'Review your activity and progress here.',
  tooltipPosition: TooltipPosition.auto,
  animation: TourAnimation.pulse,
  spotlightShape: SpotlightShape.roundedRectangle,
  spotlightPadding: 10,
  spotlightRadius: 16,
  scrollToTarget: true,
)
```

Use `TooltipPosition.top`, `bottom`, `left`, `right`, or `auto`. Available animations are `none`, `pulse`, `glow`, `ripple`, `bounce`, and `floating`.

## Custom theme

Set defaults for the complete tour with `TourTheme`. Individual `TourStep` values override the relevant spotlight and positioning defaults.

```dart
final controller = TourController(
  theme: const TourTheme(
    overlayColor: Color(0xff102a43),
    overlayOpacity: 0.72,
    spotlightPadding: 10,
    spotlightRadius: 16,
    spotlightShape: SpotlightShape.roundedRectangle,
    progressIndicatorType: TourProgressIndicatorType.fraction,
    showPreviousButton: true,
    showSkipButton: true,
  ),
  steps: steps,
);
```

Supported spotlight shapes are `rectangle`, `roundedRectangle`, `circle`, and `oval`. Individual `TourStep` values override the relevant theme defaults.

## Lifecycle callbacks and status

The controller exposes callbacks for analytics or application behavior without requiring an analytics dependency:

```dart
final controller = TourController(
  steps: steps,
  onStarted: () => debugPrint('Tour started'),
  onStepChanged: (step) => debugPrint('Showing ${step.id}'),
  onCompleted: () => debugPrint('Tour completed'),
  onSkipped: () => debugPrint('Tour skipped'),
  onDismissed: () => debugPrint('Tour dismissed'),
);
```

Use `controller.status` when surrounding UI needs to react to `idle`, `running`, `completed`, or `skipped`.

## Persistence

Persistence is optional. The controller does not require storage, and the package includes a `SharedPreferencesTourStorage` adapter:

```dart
const storage = SharedPreferencesTourStorage();

final controller = TourController(
  steps: steps,
  storage: storage,
  onCompleted: () => storage.markSeen('home-tour-v2'),
  onSkipped: () => storage.markSeen('home-tour-v2'),
);
```

To use another persistence system, implement `TourStorage`. Use a new ID, such as `home-tour-v2`, when an updated tour should be shown again.

## Async steps

Use `onBeforeShow` when a target must be prepared before its step is shown.

```dart
TourStep(
  id: TourId('products'),
  targetKey: productsKey,
  title: 'Products',
  description: 'Browse your product catalog here.',
  onBeforeShow: () async {
    await loadProducts();
  },
)
```

## Custom tooltip

Replace the default tooltip with `TourScope.tooltipBuilder`:

```dart
TourScope(
  controller: controller,
  tooltipBuilder: (context, step, controller, targetRect, screenSize, theme) {
    return Material(
      color: theme.tooltipBackgroundColor ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(step.title),
      ),
    );
  },
  child: page,
)
```

The builder receives the active step, controller, target rectangle, screen size, and resolved theme.

## Example project

The [`example/`](example/) application demonstrates a workspace-style screen with:

- Search, drawer, profile, insights, and create targets
- A scrollable multi-step tour
- Automatic tooltip positioning
- Spotlight shapes and animations
- Skip and completion persistence using the versioned ID `home-tour-v2`

Run it with:

```bash
cd example
flutter pub get
flutter run
```

## Limitations

- Targets must be mounted in the widget tree before their steps can be displayed.
- For targets created only when a drawer, dialog, or route opens, use `onBeforeShow` to show that UI first.
- Use `tooltipBuilder` when the default tooltip does not fit your design.

## License

This package is available under the MIT license. See [LICENSE](LICENSE) for details.
