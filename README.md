# flutter_app_tour

A lightweight, customizable guided-tour overlay for Flutter onboarding flows and feature discovery.

`flutter_app_tour` highlights real widgets in your app, positions a tooltip around each target, and provides simple step navigation without adding a state-management framework.

## Why flutter_app_tour?

- Small public API built around `TourController`, `TourStep`, `TourTarget`, and `TourScope`.
- No Bloc, Riverpod, Provider, GetX, or other state-management dependency.
- Automatic target scrolling when a step is outside a scrollable viewport.
- Customizable overlay, spotlight, tooltip, progress, and button styling.
- Optional persistence through an injectable `TourStorage` implementation.

## Features

- Multi-step tours with safe `start`, `next`, `previous`, `skip`, `complete`, and `reset` controls.
- Lifecycle state through `TourStatus`: `idle`, `running`, `completed`, and `skipped`.
- Tooltip placement with `TooltipPosition.top`, `bottom`, `left`, `right`, or `auto`.
- Spotlight shapes: `rectangle`, `roundedRectangle`, `circle`, and `oval`.
- Per-step animation, spotlight, tooltip, async preparation, and scrolling options.
- Default tooltip with title, description, navigation buttons, and step indicator.
- Custom tooltip builder support through `TourScope`.

## Requirements

- Flutter `3.44.0` or later
- Dart `3.12.2` or later

## Installation

Add the latest version shown on pub.dev to your app's `pubspec.yaml`:

```yaml
dependencies:
  flutter_app_tour: ^0.0.2
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

## Step customization

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

Available animations are `none`, `pulse`, `glow`, `ripple`, `bounce`, and `floating`.

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

`TourTheme` also supports tooltip colors, text styles, padding, margins, elevation, shadow, arrows, progress indicators, and button styles.

## Tooltip positioning

Use a fixed position when the layout is known, or use `TooltipPosition.auto` to choose from the available space around the target. The positioner keeps the tooltip within the configured screen margin and supports small screens, orientation changes, and scrollable content.

```dart
TourStep(
  id: TourId('save'),
  targetKey: saveKey,
  title: 'Save your work',
  description: 'Tap here to save your progress.',
  tooltipPosition: TooltipPosition.auto,
)
```

## Spotlight shapes

Choose a global default with `TourTheme.spotlightShape` or override it for a specific step:

```dart
TourStep(
  id: TourId('avatar'),
  targetKey: avatarKey,
  title: 'Your avatar',
  description: 'Open your profile from here.',
  spotlightShape: SpotlightShape.circle,
)
```

Supported shapes are `rectangle`, `roundedRectangle`, `circle`, and `oval`.

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

Observe `controller.status` when the surrounding UI needs to react to the lifecycle. Calls that are invalid for the current state are ignored safely: for example, `next()` while idle and `previous()` on the first step do nothing.

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

You can also use the compatibility helpers:

```dart
final hasSeen = await TourController.hasSeenTour('home-tour-v2');
if (!hasSeen) {
  await controller.start();
  await TourController.markTourAsSeen('home-tour-v2');
}
```

For a new version of an existing tour, change its persistence ID, for example from `home-tour-v1` to `home-tour-v2`. Existing users will then be eligible for the new tour.

To use another persistence system, implement `TourStorage` with `hasSeen`, `markSeen`, and `reset`.

## Async steps

Use `onBeforeShow` when a step needs asynchronous preparation. If the callback throws, that step is skipped and the controller continues safely.

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

The builder receives the active step, controller, highlighted rectangle, screen size, and resolved theme.

## Accessibility

Use meaningful titles and descriptions, and keep the wrapped target's existing semantic labels intact. The default tooltip uses standard Flutter text and button widgets, so it participates in Flutter's semantics tree. Provide tooltips for icon-only controls, as shown in the quick-start example.

## Example project

The [`example/`](example/) application demonstrates a workspace-style screen with:

- Search, profile, insights, and create targets
- A scrollable multi-step tour
- Automatic tooltip positioning
- Spotlight shapes and a fraction indicator
- Skip and completion persistence using the versioned ID `home-tour-v2`

Run it with:

```bash
cd example
flutter pub get
flutter run
```

## API documentation

The complete API reference is generated from the public dartdoc comments and is available on the package's pub.dev page after publication. The public entry point is:

```dart
import 'package:flutter_app_tour/flutter_app_tour.dart';
```

## Limitations

- Targets must be mounted in the widget tree before their steps can be displayed.
- Persistence is opt-in and must be marked by the application after completion or skipping.
- The built-in tooltip is intentionally simple; use `tooltipBuilder` for a fully custom layout.
- Keyboard-specific navigation and focus traversal are left to the host application.

## License

This package is available under the MIT license. See [LICENSE](LICENSE) for details.
