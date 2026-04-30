<!--
Title format: <type>: <imperative summary>
  e.g. `fix: handle -1 sentinel from UIDevice.batteryLevel on Simulator`
       `feat: expose isCharging convenience getter on BatteryInfo`
       `chore: bump pana threshold from 30 to 20`
-->

## Description

<!--
What changed and why. Lead with the user-visible effect (or the bug
symptom this fixes), then the mechanism. Link the beads ticket if
this resolves one: `Closes battery_monitor-xxx`.
-->

## Type of Change

<!-- Mark one with [x]; delete the rest. -->

- [ ] **Bug fix** — non-breaking change that fixes an issue
- [ ] **Feature** — non-breaking change that adds functionality
- [ ] **Chore** — refactor, CI, docs, dependency bump, or other
      maintenance with no observable runtime effect
- [ ] **Breaking change** — fix or feature that would change existing
      public API behavior (requires major version bump)

## Testing Performed

<!--
List the gates run locally. Cross out anything that doesn't apply.
The CI matrix re-runs all of these on Flutter 3.41.7 (pin) and
3.35.0 (declared SDK floor) -- if a leg fails only on the floor,
that's a real signal, not a flake.
-->

- [ ] `fvm dart format --output=none --set-exit-if-changed .`
- [ ] `fvm dart analyze`
- [ ] `fvm flutter test` (unit tests)
- [ ] `(cd example && fvm flutter analyze && fvm flutter test)`
- [ ] `(cd example && fvm flutter build apk --debug)` (Android-touching changes)
- [ ] `(cd example && fvm flutter build ios --simulator --no-codesign)` (iOS-touching changes)
- [ ] Manual run on a real device / Simulator / Emulator <!-- describe -->

## Checklist

<!-- Required for every PR. Skipped items must be justified inline. -->

- [ ] Public API additions / changes have dartdoc comments
      (`public_member_api_docs` is enforced by the analyzer)
- [ ] `CHANGELOG.md` updated under the next-release section
- [ ] `pubspec.yaml` `version:` bumped following semver
      (patch for fixes, minor for features, major for breaking changes)
- [ ] Local `pana --no-warning .` score ≥ 130/160 (CI gate threshold)
- [ ] `flutter pub publish --dry-run` is clean (no new warnings)
- [ ] If a native channel signature changed, both
      `BatteryStatusPlugin.kt` and `BatteryStatusPlugin.swift` were
      updated together with the matching Dart `…Channel` wrapper
- [ ] If the SDK floor was raised, `pubspec.yaml` constraints and
      `.github/workflows/ci.yml` matrix entries were updated together
