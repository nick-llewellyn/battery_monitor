import 'dart:async';
import 'dart:developer' as developer;

import 'package:battery_status/src/models/battery_info.dart';
import 'package:battery_status/src/platform/battery_level_channel.dart';
import 'package:battery_status/src/platform/battery_save_mode_channel.dart';
import 'package:battery_status/src/platform/battery_state_channel.dart';
import 'package:flutter/foundation.dart';

/// Captures a single battery error observed on one of the underlying
/// channels.
///
/// Held in [BatteryProvider.batteryErrors] as a bounded ring buffer
/// (most recent first, capped at 10 entries) so consumers can surface
/// diagnostic state without subscribing to the per-channel error
/// streams directly.
class BatteryError {
  /// Creates a battery error.
  const BatteryError({
    required this.errorType,
    required this.error,
    required this.timestamp,
    this.stackTrace,
  });

  /// Human-readable label identifying which channel raised the error
  /// (e.g. `'Battery Level'`, `'Battery State'`, `'Battery Save Mode'`).
  final String errorType;

  /// The original error object emitted by the channel's stream.
  final Object error;

  /// Wall-clock timestamp when the provider received the error.
  final DateTime timestamp;

  /// Stack trace associated with [error], if the channel supplied one.
  final StackTrace? stackTrace;

  @override
  String toString() => '[$errorType] $error';
}

/// Reactive battery monitor backed by the three native [EventChannel]
/// wrappers ([BatteryLevelChannel], [BatteryStateChannel],
/// [BatterySaveModeChannel]).
///
/// Subscribes on construction and exposes the latest values through
/// [ValueListenable]s so consumers can bind them to
/// [ValueListenableBuilder] without any third-party reactive
/// framework. Construction-time channel injection allows unit tests
/// to drive the provider with synthetic [StreamController]s instead
/// of a platform binding.
///
/// Always call [dispose] to release the native subscriptions and the
/// underlying notifiers.
class BatteryProvider {
  /// Creates a battery provider.
  ///
  /// Channel parameters are optional and intended primarily for
  /// dependency injection in unit tests. When omitted, the
  /// provider constructs default [BatteryLevelChannel],
  /// [BatteryStateChannel], and [BatterySaveModeChannel] instances
  /// bound to the real platform [EventChannel]s.
  BatteryProvider({
    BatteryLevelChannel? batteryLevelChannel,
    BatteryStateChannel? batteryStateChannel,
    BatterySaveModeChannel? batterySaveModeChannel,
  }) : _batteryLevelChannel = batteryLevelChannel ?? BatteryLevelChannel(),
       _batteryStateChannel = batteryStateChannel ?? BatteryStateChannel(),
       _batterySaveModeChannel =
           batterySaveModeChannel ?? BatterySaveModeChannel() {
    _initialize();
  }

  final BatteryLevelChannel _batteryLevelChannel;
  final BatteryStateChannel _batteryStateChannel;
  final BatterySaveModeChannel _batterySaveModeChannel;

  final ValueNotifier<double> _batteryLevel = ValueNotifier<double>(0);
  final ValueNotifier<ChargingState> _chargingState =
      ValueNotifier<ChargingState>(ChargingState.unknown);
  final ValueNotifier<bool> _batterySaveMode = ValueNotifier<bool>(false);

  /// Latest battery percentage (0..100), updated as the native
  /// channel emits.
  ValueListenable<double> get batteryLevel => _batteryLevel;

  /// Latest charging state, updated as the native channel emits.
  ValueListenable<ChargingState> get chargingState => _chargingState;

  /// Latest power-save flag, updated as the native channel emits.
  ValueListenable<bool> get batterySaveMode => _batterySaveMode;

  /// Bounded log of recent channel errors (most recent first, capped
  /// at 10 entries). Cleared via [clearErrors].
  final ValueNotifier<List<BatteryError>> batteryErrors =
      ValueNotifier<List<BatteryError>>(<BatteryError>[]);

  StreamSubscription<int>? _batteryLevelSubscription;
  StreamSubscription<ChargingState>? _batteryStateSubscription;
  StreamSubscription<bool>? _batterySaveModeSubscription;

  void _initialize() {
    developer.log('Battery provider initializing', name: 'BatteryProvider');

    _batteryLevelSubscription = _batteryLevelChannel.onBatteryLevelChanged
        .listen(
          (level) {
            developer.log('Battery level: $level%', name: 'BatteryProvider');
            _batteryLevel.value = level.toDouble();
          },
          onError: (Object error, StackTrace stackTrace) {
            _addError('Battery Level', error, stackTrace);
          },
        );

    _batteryStateSubscription = _batteryStateChannel.onBatteryStateChanged
        .listen(
          (state) {
            developer.log('Battery state: $state', name: 'BatteryProvider');
            _chargingState.value = state;
          },
          onError: (Object error, StackTrace stackTrace) {
            _addError('Battery State', error, stackTrace);
          },
        );

    _batterySaveModeSubscription = _batterySaveModeChannel
        .onBatterySaveModeChanged
        .listen(
          (isEnabled) {
            developer.log(
              'Battery save mode: $isEnabled',
              name: 'BatteryProvider',
            );
            _batterySaveMode.value = isEnabled;
          },
          onError: (Object error, StackTrace stackTrace) {
            _addError('Battery Save Mode', error, stackTrace);
          },
        );
  }

  void _addError(String errorType, Object error, StackTrace stackTrace) {
    developer.log(
      '$errorType error: $error',
      name: 'BatteryProvider',
      level: 1000,
      stackTrace: stackTrace,
    );

    final batteryError = BatteryError(
      errorType: errorType,
      error: error,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );

    final errors = List<BatteryError>.from(batteryErrors.value)
      ..insert(0, batteryError);
    if (errors.length > 10) {
      errors.removeLast();
    }
    batteryErrors.value = errors;
  }

  /// Clears all recorded battery errors.
  void clearErrors() {
    batteryErrors.value = <BatteryError>[];
  }

  /// Cancels the three native subscriptions and disposes the internal
  /// notifiers. Idempotent.
  void dispose() {
    _batteryLevelSubscription?.cancel();
    _batteryStateSubscription?.cancel();
    _batterySaveModeSubscription?.cancel();
    _batteryLevel.dispose();
    _chargingState.dispose();
    _batterySaveMode.dispose();
    batteryErrors.dispose();
  }
}
