import 'dart:async';

import 'package:flutter/services.dart';

/// Platform channel for battery level change notifications.
///
/// Exposes a stream of integer battery percentages (0..100). Backed by
/// the `com.nllewellyn.battery_status/battery_level` [EventChannel].
/// Both native handlers drop unknown readings (e.g., iOS Simulator,
/// Android battery extras missing) rather than forwarding sentinel
/// values, so the stream only carries levels in the documented range.
///
/// **Platform-specific behavior:**
/// - **iOS:** Event-driven via `UIDeviceBatteryLevelDidChangeNotification`.
///   Fires on every 1% battery level change (iOS 8+). No polling.
/// - **Android:** Event-driven via `Intent.ACTION_BATTERY_CHANGED`.
///   The sticky broadcast yields an immediate initial value and
///   subsequent updates whenever the level changes.
///
/// **Usage:**
/// ```dart
/// final channel = BatteryLevelChannel();
/// channel.onBatteryLevelChanged.listen((level) {
///   print('Battery level: $level%');
/// });
/// ```
class BatteryLevelChannel {
  /// Creates a battery level channel.
  ///
  /// An optional [eventStream] can be provided for testing to bypass
  /// the platform [EventChannel]. The injected stream replaces the
  /// real broadcast source so unit tests can drive arbitrary values
  /// without a binding to native code.
  BatteryLevelChannel({Stream<dynamic>? eventStream})
    : _eventStream = eventStream;

  /// Event channel name for battery level notifications.
  static const EventChannel _eventChannel = EventChannel(
    'com.nllewellyn.battery_status/battery_level',
  );

  /// Isolate-wide cache of the mapped platform broadcast stream.
  ///
  /// `static` fields in Dart are scoped to the enclosing isolate, so
  /// this cache is shared across every [BatteryLevelChannel] instance
  /// constructed in the main Dart isolate (which is where Flutter's
  /// platform channels are wired). Spawned isolates that import this
  /// library would each get their own cache, but they cannot reach the
  /// platform channel either.
  ///
  /// Calling [EventChannel.receiveBroadcastStream] more than once for
  /// the same channel name re-registers the binary-messenger handler
  /// and silences earlier subscribers, so every wrapper instance backed
  /// by the real [EventChannel] must share the same mapped stream.
  static Stream<int>? _sharedPlatformStream;

  final Stream<dynamic>? _eventStream;
  Stream<int>? _injectedStream;

  /// Stream of battery level changes (0..100).
  ///
  /// Emits integer values from 0 to 100 representing the battery
  /// percentage. On iOS this is backed by
  /// `UIDeviceBatteryLevelDidChangeNotification`; on Android it is
  /// backed by `Intent.ACTION_BATTERY_CHANGED`.
  ///
  /// Unknown readings (e.g., the iOS Simulator, or Android battery
  /// extras missing) are dropped at the native layer and never reach
  /// this stream.
  ///
  /// The mapped broadcast stream is shared isolate-wide for the
  /// production path, so any number of [BatteryLevelChannel] instances
  /// (and any number of `BatteryProvider`s constructed from them) all
  /// observe the same underlying
  /// [EventChannel.receiveBroadcastStream] subscription. When an
  /// `eventStream` is injected for testing, the cache is per-instance
  /// so each test fixture stays isolated.
  ///
  /// **Error handling:**
  /// - Throws an [Exception] if the platform returns an invalid type.
  /// - Platform errors are propagated through the stream's error
  ///   channel.
  Stream<int> get onBatteryLevelChanged {
    final injected = _eventStream;
    if (injected != null) {
      return _injectedStream ??= injected.map(_mapLevel);
    }
    return _sharedPlatformStream ??= _eventChannel.receiveBroadcastStream().map(
      _mapLevel,
    );
  }

  static int _mapLevel(dynamic level) {
    if (level is int) {
      return level;
    }
    if (level is double) {
      return level.toInt();
    }
    throw Exception('Invalid battery level type: ${level.runtimeType}');
  }
}
