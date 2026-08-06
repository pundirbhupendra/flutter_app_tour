# flutter_app_tour

A lightweight, customizable guided tour overlay for Flutter apps.

## Getting Started

TODO: Add installation and usage instructions.

```dart
final actionKey = GlobalKey();
final step = TourStep(
  id: 'save-button',
  targetKey: actionKey,
  title: 'Save your work',
  description: 'Tap here when you are ready.',
);
final controller = TourController(steps: [step]);

TourTarget(
  id: 'save-button',
  controller: controller,
  targetKey: actionKey,
  child: FilledButton(onPressed: save, child: const Text('Save')),
);
```

Configure the overlay and persist completed tours as needed:

```dart
final controller = TourController(
  steps: [step],
  theme: const TourTheme(
    overlayColor: Colors.black54,
    tooltipBorderRadius: BorderRadius.all(Radius.circular(16)),
  ),
);

final hasSeenOnboarding = await TourController.hasSeenTour('onboarding-v1');
if (!hasSeenOnboarding) {
  await controller.show(context);
}

// Call this from your app after the user completes or skips the tour.
await TourController.markTourAsSeen('onboarding-v1');
```
