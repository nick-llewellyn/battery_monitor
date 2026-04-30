import 'dart:async';

import 'package:battery_status/src/models/battery_info.dart';
import 'package:flutter/services.dart';

/// Platform channel for battery charging state change notifications.
///
/// Exposes a stream of [ChargingState] values backed by the
/// `com.nllewellyn.battery_status/battery_state` [EventChannel].
///
/// **Platform-specific behavior:**
/// - **iOS:** Event-driven via `UIDevice.batteryStateDidChangeNotification`.
///   Fires when the charging state changes (charging, discharging,
///   full, unknown).
/// - **Android:** Event-driven via `Intent.ACTION_BATTERY_CHANGED`.
///   The sticky broadcast yields an immediate initial value and
///   subsequent updates on changes.
///
/// **Usage:**
/// ```dart
/// final channel = BatteryStateChannel();
/// channel.onBatteryStateChanged.listen((state) {
///   print('Battery state: $state');
/// });
/// ```
class BatteryStateChannel {
  /// Creates a battery state channel.
  ///
  /// An optional [eventStream] can be provided for testing to bypass
  /// the platform [EventChannel].
  BatteryStateChannel({Stream<dynamic>? eventStream})
    : _eventStream = eventStream;

  /// Event channel name for battery state notifications.
  static const EventChannel _eventChannel = EventChannel(
    'com.nllewellyn.battery_status/battery_state',
  );

  /// Isolate-wide cache of the mapped platform broadcast stream.
  ///
  /// `static` fields in Dart are scoped to the enclosing isolate, so
  /// this cache is shared across every [BatteryStateChannel] instance
  /// constructed in the main Dart isolate (which is where Flutter's
  /// platform channels are wired). Spawned isolates that import this
  /// library would each get their own cache, but they cannot reach the
  /// platform channel either.
  ///
  /// Calling [EventChannel.receiveBroadcastStream] more than once for
  /// the same channel name re-registers the binary-messenger handler
  /// and silences earlier subscribers, so every wrapper instance backed
  /// by the real [EventChannel] must share the same mapped stream.
  static Stream<ChargingState>? _sharedPlatformStream;

  final Stream<dynamic>? _eventStream;
  Stream<ChargingState>? _injectedStream;

  /// Stream of battery charging state changes.
  ///
  /// Emits [ChargingState] values representing the current charging
  /// state. On iOS this is backed by
  /// `UIDevice.batteryStateDidChangeNotification`; on Android it is
  /// backed by `Intent.ACTION_BATTERY_CHANGED`.
  ///
  /// The mapped broadcast stream is shared isolate-wide for the
  /// production path, so any number of [BatteryStateChannel] instances
  /// (and any number of `BatteryProvider`s constructed from them) all
  /// observe the same underlying
  /// [EventChannel.receiveBroadcastStream] subscription. When an
  /// `eventStream` is injected for testing, the cache is per-instance
  /// so each test fixture stays isolated.
  ///
  /// **Mapping from native int values:**
  /// - 0 = [ChargingState.unknown]
  /// - 1 = [ChargingState.charging]
  /// - 2 = [ChargingState.discharging]
  /// - 3 = [ChargingState.full]
  /// - 4 = [ChargingState.connectedNotCharging] (Android only)
  /// - any other value = [ChargingState.unknown]
  ///
  /// **Error handling:**
  /// - Throws an [Exception] if the platform returns a non-int.
  /// - Platform errors are propagated through the stream's error
  ///   channel.
  Stream<ChargingState> get onBatteryStateChanged {
    final injected = _eventStream;
    if (injected != null) {
      return _injectedStream ??= injected.map(_mapState);
    }
    return _sharedPlatformStream ??= _eventChannel.receiveBroadcastStream().map(
      _mapState,
    );
  }

  static ChargingState _mapState(dynamic stateCode) {
    if (stateCode is! int) {
      throw Exception('Invalid battery state type: ${stateCode.runtimeType}');
    }
    switch (stateCode) {
      case 1:
        return ChargingState.charging;
      case 2:
        return ChargingState.discharging;
      case 3:
        return ChargingState.full;
      case 4:
        return ChargingState.connectedNotCharging;
      case 0:
      default:
        return ChargingState.unknown;
    }
  }
}
