# Publishing to pub.dev

Pre-flight checklist for `dart pub publish`. Owned by `battery_monitor-0u7`;
unblocks the automated release workflow (`battery_monitor-f5b`, CI-8).

The two CI gates that already protect this path on every push to `main`:

- `pana --exit-code-threshold 30` (CI-3)
- `flutter pub publish --dry-run` (CI-3)

Both currently pass. This document covers the items those gates cannot
catch and the manual steps required around the first publish.

## Blockers

These must be resolved before the first publish; they are not gated by CI.

### 1. Repository visibility

Pana 0.22+ does a live `HEAD` against `homepage`, `repository`, and
`issue_tracker`. The repo is currently `PRIVATE`, so all three resolve
to a 404 for the pana runner and cost 10/30 in the *Follow Dart file
conventions* section.

Resolution: flip the repo to public before the first publish, or change
the three URLs in `pubspec.yaml` to a public mirror.

### 2. Package description length

`pubspec.yaml` currently has a 198-character `description`. Pana enforces
a 60–180 character window (search engines truncate beyond ~180). Trim to
fit; one acceptable form:

> Event-driven battery level, charging state, and power-save mode for
> Flutter. Native EventChannels on Android and iOS, ValueListenable API.

(176 chars.)

### 3. Pub.dev trusted publisher

CI-8 publishes via OIDC, not a long-lived token. Before the release
workflow can succeed:

1. Visit `https://pub.dev/packages/battery_monitor/admin` (after first
   manual publish) → *Automated publishing*.
2. Add GitHub Actions as a trusted publisher pointed at
   `nick-llewellyn/battery_monitor`, workflow `.github/workflows/release.yml`,
   environment unset.

The first publish has to happen manually with `flutter pub publish` from
a maintainer's machine — pub.dev only enables the trusted-publisher UI
once a package exists.

## Already satisfied

| Item | Status | Evidence |
|---|---|---|
| Flutter version constraint relaxed | done | `pubspec.yaml` line 35 reads `flutter: '>=3.35.0'` (not pinned to 3.41.7). |
| `dart pub publish --dry-run` clean | done | Reported 0 warnings on 2026-04-29. |
| LICENSE present | done | OSI-approved MIT, root of repo. |
| CHANGELOG present | done | `## 0.1.0` heading at top, matches `pubspec.yaml` version. |
| Example app | done | `example/lib/main.dart` satisfies the example presence check; no `example/example.md` needed. |
| Topics declared | done | `pubspec.yaml` lists `battery`, `power`, `hardware`, `platform-channels`. |
| Static analysis | done | Pana scores 50/50. |
| Up-to-date dependencies | done | Pana scores 40/40. |

## Known score leaks (non-blocking)

Documented so they are not treated as regressions in CI-3.

### Platform support: 10/20

Pana awards 20/20 only for packages supporting all six platforms
(Android, iOS, Web, macOS, Windows, Linux). This package is
intentionally Android+iOS only; desktop is tracked in
`battery_monitor-rue` and web has no equivalent battery API. Accept the
10-point penalty unless desktop ships.

### Swift Package Manager: partial

Pana reports `ios/battery_monitor/Package.swift` missing. Flutter's iOS
plugin tooling now prefers SPM over CocoaPods; not having a manifest
costs a fraction of the platform-support score. Track separately
(future ticket); not a publish blocker.

### Screenshots: not yet declared

`screenshots/` directory and the corresponding `pubspec.yaml` entry are
both absent. Adding them would surface the example app on pub.dev.
Tracked in `battery_monitor-y4h`. Not a publish blocker.

## Release procedure (manual, first publish only)

```bash
# 1. Clean working tree on main, version bumped, CHANGELOG updated
git status                                    # must be clean
grep '^version:' pubspec.yaml                 # must match CHANGELOG
grep '^## ' CHANGELOG.md | head -1            # must match pubspec

# 2. Re-run the gates locally
fvm dart pub global run pana --exit-code-threshold 30 .
fvm flutter pub publish --dry-run

# 3. Tag and publish
git tag v$(grep '^version:' pubspec.yaml | awk '{print $2}')
fvm flutter pub publish                       # interactive auth
git push origin main --tags
```

After this completes once, configure trusted publisher (see *Blockers
§3*) and subsequent releases run from the CI-8 workflow on tag push.

## When to re-run pana locally

Pana is run in CI on every push, so local invocation is only needed
when:

- Editing `pubspec.yaml` metadata (description, URLs, topics).
- Adding or removing a top-level `lib/` export.
- Touching the `LICENSE`, `README.md`, or `CHANGELOG.md`.

Otherwise rely on the CI gate.
