import 'dart:async';

import 'package:flutter/services.dart';

/// Platform channel for battery level change notifications.
///
/// Exposes a stream of integer battery percentages (0..100). Backed by
/// the `com.nllewellyn.battery_monitor/battery_level` [EventChannel].
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
    'com.nllewellyn.battery_monitor/battery_level',
  );

  final Stream<dynamic>? _eventStream;
  Stream<int>? _onBatteryLevelChanged;

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
  /// The mapped broadcast stream is cached per channel instance, so
  /// repeated reads of this getter -- and multiple subscribers -- share
  /// the same underlying [EventChannel.receiveBroadcastStream]
  /// subscription. Without that caching, every read would re-register
  /// the binary messenger handler and silence earlier subscribers.
  ///
  /// **Error handling:**
  /// - Throws an [Exception] if the platform returns an invalid type.
  /// - Platform errors are propagated through the stream's error
  ///   channel.
  Stream<int> get onBatteryLevelChanged {
    return _onBatteryLevelChanged ??=
        (_eventStream ?? _eventChannel.receiveBroadcastStream()).map((
          dynamic level,
        ) {
          if (level is int) {
            return level;
          }
          if (level is double) {
            return level.toInt();
          }
          throw Exception('Invalid battery level type: ${level.runtimeType}');
        });
  }
}
