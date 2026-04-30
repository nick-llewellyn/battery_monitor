# battery_monitor_example

Showcase app for the [`battery_status`](../) Flutter plugin.

Builds a single `BatteryProvider` / `BatteryState` pair, binds the
composed `ValueListenable<BatteryInfo?>` to `ValueListenableBuilder`s,
and renders the live battery level, charging state, and Low Power Mode
flag straight from the native EventChannels.

## Run

```bash
fvm flutter pub get
fvm flutter run
```

The plugin is consumed via a `path:` dependency back to the parent
package, so changes in `../lib/` are picked up by `flutter run`
immediately without re-publishing.

## Notes

- iOS Simulator returns `level == -1` (no battery hardware) and the
  charging state stays `unknown`. Run on a physical iPhone to see live
  values.
- Android emulators report a synthetic 50% level by default; toggle
  values from a host shell with `adb shell dumpsys battery set level
  20` / `adb shell dumpsys battery reset`.
