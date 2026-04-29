# Changelog

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
