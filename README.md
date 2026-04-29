# battery_monitor

[![CI](https://github.com/nick-llewellyn/battery_monitor/actions/workflows/ci.yml/badge.svg)](https://github.com/nick-llewellyn/battery_monitor/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/nick-llewellyn/battery_monitor/branch/main/graph/badge.svg)](https://codecov.io/gh/nick-llewellyn/battery_monitor)
[![Pub Version](https://img.shields.io/pub/v/battery_monitor.svg)](https://pub.dev/packages/battery_monitor)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

---

Event-driven battery monitoring for Flutter. Battery level, charging
state, and Low Power Mode delivered as `ValueListenable`s via native
EventChannels on Android and iOS -- no polling on either side.

## Why another battery package?

The popular cross-platform options reach for periodic polling or
collapse three logically distinct sources (level, charge state,
power-save flag) onto a single channel that fires only when the OS
considers the *state* to have changed. On iOS that means battery level
updates between charge-state transitions are silently dropped.

`battery_monitor` exposes three dedicated EventChannels that map
directly onto the underlying OS notifications:

- iOS battery level rides `UIDeviceBatteryLevelDidChangeNotification`
  (fires on every 1% change).
- iOS charging state rides `UIDevice.batteryStateDidChangeNotification`.
- iOS Low Power Mode rides `NSProcessInfoPowerStateDidChange`.
- Android level + state ride `Intent.ACTION_BATTERY_CHANGED` (sticky,
  so the initial value is delivered synchronously on subscription).
- Android Battery Saver rides `PowerManager.ACTION_POWER_SAVE_MODE_CHANGED`.

The Dart layer lifts those streams into `ValueListenable`s so the UI
can consume them with a `ValueListenableBuilder`, no third-party
reactive dependency required.

## Supported platforms

| Platform | Minimum |
|----------|---------|
| Android  | API 21+ |
| iOS      | 13.0+   |
| Flutter  | 3.35.0+ |
| Dart     | 3.9.0+  |

CI exercises both the declared SDK floor (Flutter 3.35.0 / Dart 3.9)
and the version pinned in [`.fvmrc`](.fvmrc) (Flutter 3.41.7 / Dart
3.11.5) on every push.

## Install

```bash
flutter pub add battery_monitor
```

## Use

```dart
import 'package:battery_monitor/battery_monitor.dart';
import 'package:flutter/widgets.dart';

final provider = BatteryProvider(); // subscribes to native channels
final state = BatteryState(provider); // composes ValueListenable<BatteryInfo?>

// Bind to UI:
ValueListenableBuilder<BatteryInfo?>(
  valueListenable: state.batteryInfo,
  builder: (context, info, _) {
    if (info == null) return const SizedBox.shrink();
    return Text(
      'level=${info.level}% '
      'state=${info.chargingState.name} '
      'saveMode=${info.isInBatterySaveMode}',
    );
  },
);

// When done:
state.dispose(); // also disposes the underlying provider
```

## Public API

### Models

- **`BatteryInfo`** -- immutable record carrying `level`,
  `chargingState`, and `isInBatterySaveMode`. Hand-written `==`,
  `hashCode`, `toString`, and `copyWith`; `0..100` invariant on
  `level` is asserted in debug builds.
- **`ChargingState`** -- enum: `charging`, `discharging`, `full`,
  `connectedNotCharging` (Android only), `unknown`.

### Platform channels

- **`BatteryLevelChannel`** -- wraps the `com.nllewellyn.battery_monitor/battery_level`
  channel. `Stream<int> get onBatteryLevelChanged`.
- **`BatteryStateChannel`** -- wraps the
  `com.nllewellyn.battery_monitor/battery_state` channel.
  `Stream<ChargingState> get onBatteryStateChanged`.
- **`BatterySaveModeChannel`** -- wraps the
  `com.nllewellyn.battery_monitor/battery_save_mode` channel.
  `Stream<bool> get onBatterySaveModeChanged`.

### Reactive composition

- **`BatteryProvider`** -- subscribes to all three channels and exposes
  `ValueListenable<double> batteryLevel`,
  `ValueListenable<ChargingState> chargingState`,
  `ValueListenable<bool> batterySaveMode`, plus a bounded
  `ValueNotifier<List<BatteryError>> batteryErrors` (last 10 entries,
  most recent first).
- **`BatteryState`** -- composes the three provider listenables into
  one `ValueListenable<BatteryInfo?> batteryInfo`, recomputed whenever
  any of the underlying values change.

## Testing without a device

Every channel and the `BatteryProvider` accept dependency-injected
streams, so unit tests can drive the reactive layer without a platform
binding:

```dart
import 'dart:async';
import 'package:battery_monitor/battery_monitor.dart';
import 'package:test/test.dart';

void main() {
  test('updates batteryLevel from injected stream', () async {
    final levelCtrl = StreamController<dynamic>.broadcast();
    final provider = BatteryProvider(
      batteryLevelChannel: BatteryLevelChannel(eventStream: levelCtrl.stream),
    );

    levelCtrl.add(75);
    await Future<void>.delayed(Duration.zero);
    expect(provider.batteryLevel.value, 75);

    provider.dispose();
    await levelCtrl.close();
  });
}
```

See [`test/`](test/) for the full unit suite covering channel mapping,
provider composition, and error-buffer behaviour.

## Further documentation

- [`doc/architecture.md`](doc/architecture.md) -- channel architecture,
  native implementation notes, and DI reference.
- [`doc/ios_battery_level.md`](doc/ios_battery_level.md) -- why iOS
  needs a dedicated level channel separate from the state channel.
- [`doc/testing.md`](doc/testing.md) -- unit testing and physical-
  device testing guide.

## License

[MIT](LICENSE) (c) 2026 Nicholas Llewellyn.
