# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->


## Build & Test

```bash
# Set up the pinned Flutter SDK
fvm use 3.41.7 --force

# Install package + example dependencies
fvm flutter pub get
(cd example && fvm flutter pub get)

# Quality gates (mirrors CI)
fvm dart format --output=none --set-exit-if-changed .
fvm dart analyze
fvm flutter test
(cd example && fvm flutter analyze && fvm flutter test)
```

## Architecture Overview

`battery_monitor` is a Flutter plugin exposing battery level, charging
state, and Low Power Mode via three native EventChannels (Android +
iOS) lifted into reactive `signals` on the Dart side.

- `lib/src/platform/` -- thin EventChannel wrappers, one per data
  stream. Each accepts a constructor-injected `Stream<dynamic>` for
  unit testing without a platform binding.
- `lib/src/battery_provider.dart` -- subscribes to the three channels
  and surfaces them as separate `Signal`s plus a bounded
  `ValueNotifier<List<BatteryError>>` for diagnostics.
- `lib/src/battery_state.dart` -- composes the provider's three signals
  into one `Signal<BatteryInfo?>` via a `signals` `effect`.
- `android/src/.../BatteryMonitorPlugin.kt` and
  `ios/Classes/BatteryMonitorPlugin.swift` register the three
  EventChannels and wire them to per-channel stream handlers backed by
  the OS notification APIs (BroadcastReceiver / NotificationCenter).

See [`doc/architecture.md`](doc/architecture.md) for the channel
specs and DI reference.

## Conventions & Patterns

- Pin: Flutter 3.41.7 / Dart 3.11.5 via FVM (`.fvmrc`).
- All public APIs require dartdoc comments
  (`public_member_api_docs: true` in `analysis_options.yaml`).
- Strict-mode analyzer flags are on (`strict-casts`, `strict-inference`,
  `strict-raw-types`).
- Channel names are namespaced under
  `com.nllewellyn.battery_monitor/`. Both sides of the wire (native
  registration + Dart wrapper) must move together when a name
  changes.
- Tests use `package:checks` for assertions and inject
  `StreamController`s via the channels' `eventStream` constructor
  parameter -- there is no platform-channel mocking required.
