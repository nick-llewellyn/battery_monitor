# Copilot instructions for `battery_monitor`

`battery_monitor` is a Flutter plugin that exposes battery level,
charging state, and Low Power Mode as `ValueListenable`s, backed by
three native `EventChannel`s on Android and iOS. Use these notes when
generating code, summarising PRs, or reviewing diffs for this repo.

## Architecture in one screen

```
EventChannel  ─►  ChannelWrapper      ─►  BatteryProvider           ─►  BatteryState
(native side)     (lib/src/platform/)     (ValueListenable per ch.)     (ValueListenable<BatteryInfo?>)
```

- `lib/src/platform/` -- one wrapper per channel
  (`BatteryLevelChannel`, `BatteryStateChannel`,
  `BatterySaveModeChannel`). Each accepts an optional
  `Stream<dynamic> eventStream` constructor argument so unit tests
  can inject a `StreamController` instead of binding to the real
  platform channel.
- `lib/src/battery_provider.dart` -- subscribes to the three
  channels and surfaces them as separate `ValueListenable`s plus a
  bounded `ValueNotifier<List<BatteryError>>` for diagnostics.
- `lib/src/battery_state.dart` -- composes the three provider
  listenables into one `ValueListenable<BatteryInfo?>` by listening
  for changes and recomputing the immutable `BatteryInfo` snapshot.
- Native: `android/src/.../BatteryMonitorPlugin.kt` and
  `ios/Classes/BatteryMonitorPlugin.swift` register the three
  EventChannels and back them with `BroadcastReceiver` /
  `NotificationCenter` observers.

Channel names are namespaced under
`com.nllewellyn.battery_monitor/`. **The native registration and the
Dart wrapper must change together** -- a rename on one side without
the other is a silent runtime breakage.

See `doc/architecture.md` for the channel payload contracts and the
sentinel values (`-1` for unknown level, `0` for unknown state).

## Conventions to enforce in review

- **Public API requires dartdoc.** The analyzer enables
  `public_member_api_docs`; missing comments are CI failures, not
  style nits.
- **Strict analyzer flags are on:** `strict-casts`, `strict-inference`,
  `strict-raw-types`. Don't introduce `dynamic` or implicit `Object`
  parameters at API boundaries.
- **Line width is 80 columns** (Dart 3.7 tall-style formatting via
  `dart format`). Wrap long argument lists rather than disabling the
  formatter.
- **Tests use `package:checks`** for assertions, not `expect`. Follow
  the existing pattern: `check(value).equals(...)`.
- **No platform-channel mocking.** Inject a `Stream<dynamic>` via the
  channel wrapper's `eventStream` constructor parameter. If you find
  yourself reaching for `MethodChannel.setMockMethodCallHandler`, the
  test is at the wrong layer.
- **`BatteryInfo` is immutable.** It carries `==`, `hashCode`,
  `toString`, and `copyWith` hand-written, plus an assert on the
  `0..100` level invariant. Maintain all four when fields are added.

## Compatibility surface

- **Declared SDK floor:** Flutter `>=3.35.0 <4.0.0` / Dart `^3.9.0`
  in `pubspec.yaml`. CI exercises both the floor and the .fvmrc pin
  (`3.41.7` / Dart `3.11.5`). A change that compiles on the pin but
  not the floor will fail CI -- prefer language features available
  on the floor, or raise the floor explicitly with a CHANGELOG note.
- **Native floors:** Android API 21+, iOS 13.0+. Don't introduce
  symbols only available on later versions without an availability
  guard.
- **Pana score floor:** 130/160 (CI `--exit-code-threshold 30`).
  PRs that drop the score below 140 should call out which heuristic
  regressed and why.

## Review checklist Copilot should apply

When reviewing a diff, prioritise these questions in order:

1. Did the diff touch a channel name, payload type, or sentinel?
   If yes, are the Kotlin, Swift, and Dart sides all consistent?
2. Is every new public symbol documented?
3. Are tests injecting via `eventStream`, not patching the platform
   channel?
4. Does `CHANGELOG.md` have a corresponding entry, and was
   `pubspec.yaml` `version:` bumped semver-appropriately?
5. For native code: does the new code compile against the declared
   minSdk / iOS deployment target, not just the latest?

## Out of scope (do not suggest)

- A `flutter_lints` downgrade -- the package pins `^6.0.0` for the
  Dart 3.8 floor it implies; loosening pulls the floor down.
- A move off `EventChannel` to `MethodChannel` polling -- the
  push-based model is the architectural contract.
- Adding new top-level dependencies without a clear pana / size
  justification; the plugin is intentionally dependency-free
  (`flutter` only) at the runtime layer.
