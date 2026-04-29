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

  /// Isolate-wide cache of the mapped platform broadcast stream.
  ///
  /// `static` fields in Dart are scoped to the enclosing isolate, so
  /// this cache is shared across every [BatterySaveModeChannel]
  /// instance constructed in the main Dart isolate (which is where
  /// Flutter's platform channels are wired). Spawned isolates that
  /// import this library would each get their own cache, but they
  /// cannot reach the platform channel either.
  ///
  /// Calling [EventChannel.receiveBroadcastStream] more than once for
  /// the same channel name re-registers the binary-messenger handler
  /// and silences earlier subscribers, so every wrapper instance backed
  /// by the real [EventChannel] must share the same mapped stream.
  static Stream<bool>? _sharedPlatformStream;

  final Stream<dynamic>? _eventStream;
  Stream<bool>? _injectedStream;

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
  /// The mapped broadcast stream is shared isolate-wide for the
  /// production path, so any number of [BatterySaveModeChannel]
  /// instances (and any number of `BatteryProvider`s constructed from
  /// them) all observe the same underlying
  /// [EventChannel.receiveBroadcastStream] subscription. When an
  /// `eventStream` is injected for testing, the cache is per-instance
  /// so each test fixture stays isolated.
  ///
  /// **Error handling:**
  /// - Throws an [Exception] if the platform returns an invalid type.
  /// - Platform errors are propagated through the stream's error
  ///   channel.
  Stream<bool> get onBatterySaveModeChanged {
    final injected = _eventStream;
    if (injected != null) {
      return _injectedStream ??= injected.map(_mapSaveMode);
    }
    return _sharedPlatformStream ??= _eventChannel.receiveBroadcastStream().map(
      _mapSaveMode,
    );
  }

  static bool _mapSaveMode(dynamic enabled) {
    if (enabled is bool) {
      return enabled;
    }
    throw Exception('Invalid battery save mode type: ${enabled.runtimeType}');
  }
}
