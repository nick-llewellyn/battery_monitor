import 'dart:async';

import 'package:flutter/services.dart';

/// Platform channel for battery save mode state changes.
///
/// Wraps the `com.nllewellyn.battery_monitor/battery_save_mode`
/// [EventChannel] to receive Low Power Mode (iOS) / Battery Saver
/// (Android) state changes from the native platform.
///
/// **Platform behavior:**
/// - **iOS:** Uses `NSProcessInfoPowerStateDidChangeNotification` to
///   receive real-time notifications when Low Power Mode is enabled
///   or disabled.
/// - **Android:** Uses `PowerManager.ACTION_POWER_SAVE_MODE_CHANGED`
///   to receive real-time notifications when Battery Saver is
///   enabled or disabled. Requires API 21+.
///
/// **Usage:**
/// ```dart
/// final channel = BatterySaveModeChannel();
/// channel.onBatterySaveModeChanged.listen((isEnabled) {
///   print('Battery save mode: $isEnabled');
/// });
/// ```
class BatterySaveModeChannel {
  /// Creates a battery save mode channel.
  ///
  /// An optional [eventStream] can be provided for testing to bypass
  /// the platform [EventChannel].
  BatterySaveModeChannel({Stream<dynamic>? eventStream})
    : _eventStream = eventStream;

  /// The [EventChannel] for receiving battery save mode state changes.
  ///
  /// The channel name is hard-coded to match the native registration
  /// in [BatteryMonitorPlugin] on both Android and iOS.
  static const EventChannel _eventChannel = EventChannel(
    'com.nllewellyn.battery_monitor/battery_save_mode',
  );

  final Stream<dynamic>? _eventStream;

  /// Stream of battery save mode state changes.
  ///
  /// Emits `true` when battery save mode is enabled, `false` when
  /// disabled. An initial value is sent immediately upon
  /// subscription.
  ///
  /// **iOS:** Fires when Low Power Mode is toggled in
  /// Settings > Battery.
  /// **Android:** Fires when Battery Saver is toggled in
  /// Settings > Battery.
  ///
  /// **Error handling:**
  /// - Throws an [Exception] if the platform returns an invalid type.
  /// - Platform errors are propagated through the stream's error
  ///   channel.
  Stream<bool> get onBatterySaveModeChanged {
    final source = _eventStream ?? _eventChannel.receiveBroadcastStream();
    return source.map((dynamic enabled) {
      if (enabled is bool) {
        return enabled;
      }
      throw Exception('Invalid battery save mode type: ${enabled.runtimeType}');
    });
  }
}
