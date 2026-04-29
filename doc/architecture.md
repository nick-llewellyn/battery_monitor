# Channel architecture

`battery_monitor` ships three independent platform EventChannels and
two thin Dart layers on top:

```
┌───────────────────────────────────────────────────────────┐
│                       Flutter (Dart)                      │
├───────────────────────────────────────────────────────────┤
│  BatteryState  -> ValueListenable<BatteryInfo?>           │
│       │ listener-driven recompose                         │
│  BatteryProvider                                          │
│    ├─ ValueListenable<double>          batteryLevel       │
│    ├─ ValueListenable<ChargingState>   chargingState      │
│    ├─ ValueListenable<bool>            batterySaveMode    │
│    └─ ValueNotifier<List<BatteryError>> batteryErrors     │
│                                                           │
│  BatteryLevelChannel | BatteryStateChannel | …SaveModeCh. │
└───────────────────────────────────────────────────────────┘
                            │
                            │ EventChannels
        ┌───────────────────┴───────────────────┐
        │                                       │
┌───────▼────────┐                    ┌─────────▼─────────┐
│    Android     │                    │        iOS        │
├────────────────┤                    ├───────────────────┤
│ BatteryMonitor │                    │ BatteryMonitor    │
│ Plugin         │                    │ Plugin            │
│   ├─ Level     │                    │   ├─ Level        │
│   ├─ State     │                    │   ├─ State        │
│   └─ SaveMode  │                    │   └─ SaveMode     │
└────────────────┘                    └───────────────────┘
```

## Channel specifications

### Battery level

- **Channel:** `com.nllewellyn.battery_monitor/battery_level`
- **Payload:** `int` (0..100). Unknown readings are dropped at the
  native layer and never forwarded.
- **Android:** `Intent.ACTION_BATTERY_CHANGED` sticky broadcast.
  Percentage computed as `(EXTRA_LEVEL * 100) / EXTRA_SCALE`.
  `registerReceiver(null, filter)` returns the cached intent so the
  initial value is delivered synchronously on subscription. Unknown
  readings (negative `EXTRA_LEVEL` or non-positive `EXTRA_SCALE`) are
  dropped silently.
- **iOS:** `UIDeviceBatteryLevelDidChangeNotification`. Fires on every
  1% change (iOS 8+). `UIDevice.current.batteryLevel` returns a float
  in `0.0..1.0`, or `-1.0` when unknown (Simulator, or monitoring
  disabled). The handler converts to a percentage as a `Double` and
  drops the unknown sentinel rather than forwarding it. Hardware-level
  granularity is 5%, so values come through as multiples of 5 (e.g.,
  70.0, 75.0).

### Battery state

- **Channel:** `com.nllewellyn.battery_monitor/battery_state`
- **Payload:** `int` (0..4)
- **Android:** `Intent.ACTION_BATTERY_CHANGED` -> `EXTRA_STATUS`
  mapped as `CHARGING -> 1`, `DISCHARGING -> 2`, `FULL -> 3`,
  `NOT_CHARGING -> 4`, anything else -> 0.
- **iOS:** `UIDevice.batteryStateDidChangeNotification`.
  `UIDevice.batteryState` mapped as `.charging -> 1`,
  `.unplugged -> 2`, `.full -> 3`, `.unknown -> 0`.
  iOS does not surface a `connectedNotCharging` distinction.

### Battery save mode

- **Channel:** `com.nllewellyn.battery_monitor/battery_save_mode`
- **Payload:** `bool`
- **Android:** `PowerManager.ACTION_POWER_SAVE_MODE_CHANGED` broadcast,
  current value read from `PowerManager.isPowerSaveMode`. Requires
  API 21+.
- **iOS:** `NSProcessInfoPowerStateDidChange`. Current value read from
  `ProcessInfo.processInfo.isLowPowerModeEnabled`. Requires iOS 9.0+
  (always reports `false` on older versions).

## Dependency injection for testing

All three channel classes and `BatteryProvider` accept optional
constructor parameters. When omitted, real platform EventChannels are
used. When provided, the injected stream replaces the broadcast
source so unit tests can drive arbitrary values synchronously without
binding to native code.

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

levelCtrl.add(75);
await Future<void>.delayed(Duration.zero);
// provider.batteryLevel.value == 75.0
```

## Resource management

Each native handler unregisters its receiver / observer in `onCancel`
so subscriptions left dangling do not leak. The Dart `BatteryProvider`
cancels its three `StreamSubscription`s and disposes its four
`ValueNotifier`s (the three value notifiers backing the public
`ValueListenable`s plus `batteryErrors`) in `dispose`.
`BatteryState.dispose` detaches its listeners, disposes its internal
`ValueNotifier`, and forwards to the underlying provider.

The three channel wrappers share their mapped platform broadcast
stream process-wide via a static cache. The first read of
`onBatteryLevelChanged` / `onBatteryStateChanged` /
`onBatterySaveModeChanged` (on any instance, in any
`BatteryProvider`) calls `EventChannel.receiveBroadcastStream()`
once, maps it to the typed stream, and every subsequent read on any
instance returns the same `Stream` object. This keeps the single
binary messenger handler for each channel name alive for the
lifetime of the process, so independent `BatteryProvider`s can
coexist without the second one silencing the first. Per-instance
caching only kicks in when an `eventStream` is injected for testing,
so unit fixtures stay isolated.

## Error handling

- Invalid channel payload types throw an `Exception` with a descriptive
  message; the error propagates through the stream's error channel.
- `BatteryProvider` catches per-channel errors, logs them via
  `dart:developer.log`, and appends them to a bounded ring buffer
  (`batteryErrors`, capped at 10 most-recent entries). `clearErrors`
  empties the buffer.
