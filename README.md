# Indoor Navigation

A Flutter prototype for hospital indoor navigation. It calculates routes across
three floors, adapts them for accessibility preferences, and guides users with
floor maps, step-by-step instructions, and an animated perspective view.

> This is a local prototype. Login, beacon detection, and movement are
> simulated; no backend or real Bluetooth scanner is connected.

## Features

- Destination selection from hospital rooms and entrances
- Dijkstra shortest-path routing over a bundled navigation graph
- Accessibility-aware routing:
  - **Wheelchair:** blocks stairs and prefers lifts
  - **Assisted:** penalizes stairs and prefers lifts
- Configurable building conditions: normal, emergency, maintenance, and high
  traffic
- Turn, walking, lift, stairs, and arrival instructions
- Interactive floor-map route overlay, current-location indicator, and
  destination pin
- Animated corridor-style navigation visualizer
- Simulated beacon updates, automatic rerouting, and manual re-centering
- Bundled demo scenarios for repeatable routes

## Requirements

- Flutter SDK compatible with Dart `^3.10.7`
- A supported Flutter target (Android, iOS, web, Windows, macOS, or Linux)

## Run locally

```bash
flutter pub get
flutter run
```

To check static analysis and run tests:

```bash
flutter analyze
flutter test
```

## How to use the app

1. Enter any syntactically valid email and a password with at least six
   characters. Authentication is simulated.
2. Confirm or select your current location.
3. Select a destination and press **GO NOW**.
4. On the navigation screen, use **View Map** to switch between the animated
   guidance view and the current floor plan.
5. Press **I AM HERE** after completing an instruction. The prototype advances
   to the expected route node.
6. Press **NO** for a contextual hint, or **I AM LOST – RE-CENTER** to select
   your current location manually and recalculate the route.

## Architecture

```text
UI screens
  → NavigationState (Provider / ChangeNotifier)
  → RouteController → Dijkstra + CostModifiers → navigation graph
  → InstructionController → step-by-step instructions
  → VerificationController / BeaconEmitter → location updates and rerouting
```

### Main modules

| Location | Responsibility |
| --- | --- |
| `lib/main.dart` | App bootstrap, data loading, controller lifecycle, and screen switching |
| `lib/state/` | Shared navigation state and routing preferences |
| `lib/graph/` | Graph models, JSON loading, and route-cost rules |
| `lib/routing/` | Dijkstra algorithm and reactive route recalculation |
| `lib/instructions/` | Converts routes into human-readable guidance |
| `lib/location/` | Beacon configuration and simulated detection events |
| `lib/verification/` | Confirmation, hints, re-centering, and auto-verification |
| `lib/screens/` | Login, destination selection, settings, and active navigation UI |
| `lib/views/maps/` | SVG floor plans and painted route overlays |
| `lib/views/three_d/` | Custom-painted animated navigation scenes |
| `lib/demo/` | JSON-backed demonstration scenarios |

## Navigation data

All prototype data is bundled under `assets/data/`:

- `graph.json` defines nodes, bidirectional travel edges, costs, and map
  polylines across floors 0–2.
- `beacons.json` maps simulated beacon IDs to graph nodes.
- `scenarios.json` contains sample start/destination combinations and routing
  preferences.

Floor-plan SVGs live in `assets/maps/` and are rendered by `flutter_svg`.

## Routing behavior

`RouteController` observes `NavigationState`. When the current location,
destination, accessibility profile, or active conditions change, it calculates
a new least-cost path. `InstructionController` then regenerates instructions
from that route.

Conditions currently apply a cost multiplier to every route edge. They model
the effect of a building-wide condition, rather than blocking or slowing a
specific corridor.

## Dependencies

- `provider` — application state management
- `flutter_svg` — SVG floor-map rendering
- `flutter_cube` — included dependency for 3D scene work

## Prototype limitations

- Login is local validation only; there is no account service.
- `BeaconEmitter` simulates location events. Real BLE scanning and the Android/
  iOS permissions required for it have not been implemented.
- Demo scenarios can be loaded programmatically but are not currently exposed
  in the UI.
- Navigation state is in memory and is reset when the app restarts.
- The visualizer is a custom-painted perspective animation, not a physical 3D
  building model.

## Repository structure

```text
assets/       Navigation graph, beacon/scenario data, and SVG maps
lib/          Flutter application source
test/         Widget tests
android/      Android runner
ios/          iOS runner
web/          Web runner
windows/      Windows runner
macos/        macOS runner
linux/        Linux runner
```
