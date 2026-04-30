# iOS battery level: why a dedicated channel

iOS surfaces battery information through two notifications that do
not overlap:

- `UIDevice.batteryStateDidChangeNotification` -- fires when the
  charging *state* transitions (charging, discharging, full).
- `UIDeviceBatteryLevelDidChangeNotification` -- fires on every 1%
  battery *level* change (iOS 8+).

A consumer that only listens to the state notification will miss
every level change between charge-state transitions. On a discharging
device that means the percentage stays frozen until the next charging
event, which is a long time.

`battery_status` solves this by exposing the level and the state on
two separate EventChannels:

```
                 ┌──────────────── BatteryLevelChannel
                 │  level events   (UIDeviceBatteryLevelDidChange)
                 │
BatteryProvider ─┤
                 │  state events
                 └──────────────── BatteryStateChannel
                                   (UIDevice.batteryStateDidChange)
```

Both channels are event-driven on both platforms (no polling), so the
behaviour is symmetric across Android and iOS even though the
underlying OS APIs differ.

## Hardware granularity

iOS reports `UIDevice.current.batteryLevel` in 5% increments at the
hardware/OS layer (0.05 steps). The native handler forwards the raw
percentage as a `Double`, so consumers receive values like `70.0`,
`75.0`, `80.0`. The Dart side does no further quantisation -- the UI
layer is free to floor, round, or display fractional values.

## Simulator behaviour

The iOS Simulator has no battery hardware. `UIDevice.batteryLevel`
returns `-1.0`, and the native level handler drops the value rather
than forwarding `-1` to Flutter. The state handler still emits
`ChargingState.unknown`, so the composed `BatteryInfo` stays at
`level: 0, chargingState: unknown` until the app runs on real
hardware.

## Logs

The Dart side logs every emission via `dart:developer.log` under the
`BatteryProvider` and `BatteryState` log names. Filter Xcode console
or `flutter logs` on those names to trace events:

```
[BatteryProvider] Battery level: 84%
[BatteryProvider] Battery state: ChargingState.discharging
[BatteryState]    Battery update: level=84.0, state=…, saveMode=false
```
