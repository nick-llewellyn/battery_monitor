# Testing

## Unit tests (Dart)

All channel classes and `BatteryProvider` accept constructor-injected
streams, so the entire reactive layer can be exercised without a
device or simulator.

### Channel-level tests

```dart
import 'dart:async';
import 'package:battery_monitor/battery_monitor.dart';
import 'package:test/test.dart';

void main() {
  test('BatteryLevelChannel emits int levels', () async {
    final controller = StreamController<dynamic>.broadcast();
    final channel = BatteryLevelChannel(eventStream: controller.stream);

    final values = <int>[];
    final sub = channel.onBatteryLevelChanged.listen(values.add);

    controller.add(85);
    await Future<void>.delayed(Duration.zero);

    expect(values, [85]);
    await sub.cancel();
    await controller.close();
  });
}
```

### Provider-level tests

```dart
final levelCtrl = StreamController<dynamic>.broadcast();
final stateCtrl = StreamController<dynamic>.broadcast();
final saveModeCtrl = StreamController<dynamic>.broadcast();

final provider = BatteryProvider(
  batteryLevelChannel: BatteryLevelChannel(eventStream: levelCtrl.stream),
  batteryStateChannel: BatteryStateChannel(eventStream: stateCtrl.stream),
  batterySaveModeChannel: BatterySaveModeChannel(
    eventStream: saveModeCtrl.stream,
  ),
);

levelCtrl.add(42);
await Future<void>.delayed(Duration.zero);
expect(provider.batteryLevel.value, 42.0);
```

### Run

```bash
fvm flutter test
```

The bundled suite covers channel type mapping, provider composition,
error-buffer bounds, and `BatteryInfo` equality / `copyWith` (44
tests).

## Device testing

### Android

The `dumpsys battery` shell command lets you script every state
transition without unplugging anything:

```bash
# Drive a level
adb shell dumpsys battery set level 50

# Force charging / discharging
adb shell dumpsys battery set ac 1     # plugged in
adb shell dumpsys battery set ac 0     # unplugged

# Toggle Battery Saver
adb shell settings put global low_power 1
adb shell settings put global low_power 0

# Restore real values
adb shell dumpsys battery reset
```

### iOS

Battery Saver state can be toggled in
`Settings -> Battery -> Low Power Mode`. Charging state can only be
exercised by physically plugging / unplugging the device. Battery
level is observed by waiting for the device to discharge or charge by
1%.

The iOS Simulator has no battery hardware -- the level stream stays
silent, the state stream emits `unknown`, and the save mode stream
emits `false`. Use a physical device for iOS validation.

### Watching the logs

```bash
flutter logs | grep -E 'BatteryProvider|BatteryState'
```

## CI

`.github/workflows/ci.yml` runs `dart format --set-exit-if-changed`,
`dart analyze`, and `flutter test` on the package itself plus
`flutter analyze` on the example, gated by `paths-ignore` so doc-only
commits do not pay for the matrix. The matrix exercises both the
declared SDK floor and the version pinned in `.fvmrc`.
