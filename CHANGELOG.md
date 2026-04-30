# Changelog

## 1.0.1

Renamed-package + bug-fix release. The Dart `BatteryProvider`,
`BatteryState`, `BatteryInfo`, `ChargingState`, and the three channel
wrappers keep the same shape; only the package identifier and the
native plugin / channel namespace change.

### Renamed package

- The plugin is now published as **`battery_status`** instead of
  `battery_monitor` to resolve a naming conflict with an unrelated
  package on pub.dev. Consumers must update their import and
  dependency:
  - `dependencies: battery_monitor: ^1.0.0` ->
    `dependencies: battery_status: ^1.0.1`
  - `import 'package:battery_monitor/battery_monitor.dart';` ->
    `import 'package:battery_status/battery_status.dart';`
- Native plugin classes renamed: `BatteryMonitorPlugin` ->
  `BatteryStatusPlugin` on both Android (Kotlin) and iOS (Swift).
- Android Kotlin package + Gradle namespace:
  `com.nllewellyn.battery_monitor` ->
  `com.nllewellyn.battery_status`.
- iOS pod / SPM module: `battery_monitor` -> `battery_status`. SPM
  product name `battery-monitor` -> `battery-status`.
- EventChannel names changed to match the new namespace:
  - `com.nllewellyn.battery_monitor/battery_level` ->
    `com.nllewellyn.battery_status/battery_level`
  - `com.nllewellyn.battery_monitor/battery_state` ->
    `com.nllewellyn.battery_status/battery_state`
  - `com.nllewellyn.battery_monitor/battery_save_mode` ->
    `com.nllewellyn.battery_status/battery_save_mode`

### Bug fixes

- Android `BatteryLevelStreamHandler` no longer emits `-1` when
  `EXTRA_LEVEL` / `EXTRA_SCALE` are missing or invalid. Unknown
  readings are dropped silently to match the iOS handler, so the
  `com.nllewellyn.battery_status/battery_level` channel only carries
  values in `0..100` and `BatteryInfo`'s 0..100 assert no longer trips
  in debug builds when the platform reports an unknown level.
- `BatteryLevelChannel`, `BatteryStateChannel`, and
  `BatterySaveModeChannel` now share their mapped platform broadcast
  stream isolate-wide via a `static` cache, instead of calling
  `EventChannel.receiveBroadcastStream()` per instance. The previous
  per-instance cache silenced earlier subscribers as soon as a second
  `BatteryProvider` (or any second wrapper instance for the same
  channel name) was constructed and listened, because the new
  `receiveBroadcastStream()` call re-registered the binary messenger
  handler. The injected `eventStream` test seam stays per-instance so
  unit tests remain isolated. Regression tests cover both the
  per-class identity invariant and a two-`BatteryProvider` fan-out
  driven through the test binary messenger.

## 1.0.0

First stable release. The public API surface from 0.1.0 is unchanged
and is now committed to under semantic versioning.

### Architecture

The push-based event model is the load-bearing design choice and is
now considered stable. Battery level, charging state, and Low Power
Mode each ride a dedicated `EventChannel`, mapped 1:1 onto the
underlying OS notification (`UIDeviceBatteryLevelDidChangeNotification`,
`UIDevice.batteryStateDidChangeNotification`,
`NSProcessInfoPowerStateDidChange` on iOS;
`Intent.ACTION_BATTERY_CHANGED` and
`PowerManager.ACTION_POWER_SAVE_MODE_CHANGED` on Android). No timers,
no polling, no collapsing of the three signals onto a single channel
that would silently drop level updates between charge-state
transitions.

### iOS source layout

iOS sources moved to `ios/battery_monitor/Sources/battery_monitor/` so
a single tree feeds both Swift Package Manager (`Package.swift`) and
CocoaPods (`battery_monitor.podspec` `s.source_files`). SPM consumers
get a first-class manifest (tools version 5.9, iOS 13.0); CocoaPods
consumers see no change in behaviour. The Dart and Android layers,
plugin registration, and channel namespaces are untouched.

### Tooling

- `pana` reports 160/160 on the published artefact.
- CI publishes to pub.dev and uploads coverage to Codecov via
  tokenless OIDC trust relationships -- no long-lived secrets in the
  repository.
- `main` branch protection requires the full 6-check matrix
  (Android + iOS on Flutter 3.35.0 and the `.fvmrc`-pinned 3.41.7,
  plus `pana + publish dry-run` and `Dependency review`) and
  resolution of all review threads.

## 0.1.0

Initial release.

### Public API

- `BatteryProvider` -- subscribes to three native EventChannels and
  exposes `ValueListenable<double> batteryLevel`,
  `ValueListenable<ChargingState> chargingState`,
  `ValueListenable<bool> batterySaveMode`, plus a bounded
  `ValueNotifier<List<BatteryError>> batteryErrors` for diagnostic
  surfacing. Construction-time channel injection allows unit tests to
  drive the provider without a platform binding.
- `BatteryState` -- composes the three provider listenables into one
  `ValueListenable<BatteryInfo?> batteryInfo`, recomputed whenever any
  of the underlying values change. Takes ownership of the underlying
  `BatteryProvider` for `dispose`.
- `BatteryInfo` -- immutable record carrying `level`, `chargingState`,
  and `isInBatterySaveMode`, with hand-written `==`, `hashCode`,
  `toString`, and `copyWith`. Asserts the `0..100` invariant on
  construction so test fakes that drift out of range fail loudly.
- `ChargingState` -- enum with `charging`, `discharging`, `full`,
  `connectedNotCharging` (Android only), `unknown`.
- `BatteryLevelChannel`, `BatteryStateChannel`,
  `BatterySaveModeChannel` -- thin wrappers over the platform
  EventChannels with optional `eventStream` constructors for testing.

### Platform implementation

- **Android** (Kotlin, API 21+): `BroadcastReceiver` against
  `Intent.ACTION_BATTERY_CHANGED` for level + state, and
  `PowerManager.ACTION_POWER_SAVE_MODE_CHANGED` for save mode. The
  sticky battery intent yields an immediate initial value on
  subscription.
- **iOS** (Swift, 13.0+): `NotificationCenter` observers against
  `UIDeviceBatteryLevelDidChangeNotification`,
  `UIDevice.batteryStateDidChangeNotification`, and
  `NSProcessInfoPowerStateDidChange`. Battery monitoring is enabled
  on subscription and left enabled across the level + state handlers
  (the level handler may still need it after the state handler
  cancels).

### Channel namespace

All three channel names are namespaced under
`com.nllewellyn.battery_monitor/`:

- `com.nllewellyn.battery_monitor/battery_level` (`int`, 0..100, or
  `-1` if unknown)
- `com.nllewellyn.battery_monitor/battery_state` (`int`, 0..4)
- `com.nllewellyn.battery_monitor/battery_save_mode` (`bool`)

### Testing

- 44 unit tests covering channel type mapping, provider composition,
  error-ring-buffer bounds, and `BatteryInfo` equality / `copyWith`.
- Example app smoke test boots `BatteryMonitorExampleApp` to verify
  the consumer integration compiles and renders.
