## 0.0.2 — Unreleased

- Decouple `TourController` from Flutter `BuildContext` and widget tree.
- Add `TourScope` widget to host the overlay UI and accept a pluggable `tooltipBuilder`.
- Introduce strongly typed `TourId` for safer target identifiers.
- Fix lifecycle and scrolling issues when targets are removed during widget disposal.
- Replace delayed fades with cancelable timers to avoid pending timer warnings in tests.
- UI improvements and layout fixes (tooltip actions wrap instead of overflow).
- Update example and tests to use the new API; all tests pass.

## 0.0.1

* TODO: Describe initial release.
