import 'dart:async';

import 'package:battery_monitor/src/models/battery_info.dart';
import 'package:flutter/services.dart';

/// Platform channel for battery charging state change notifications.
///
/// Exposes a stream of [ChargingState] values backed by the
/// `com.nllewellyn.battery_monitor/battery_state` [EventChannel].
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
    'com.nllewellyn.battery_monitor/battery_state',
  );

  final Stream<dynamic>? _eventStream;
  Stream<ChargingState>? _onBatteryStateChanged;

  /// Stream of battery charging state changes.
  ///
  /// Emits [ChargingState] values representing the current charging
  /// state. On iOS this is backed by
  /// `UIDevice.batteryStateDidChangeNotification`; on Android it is
  /// backed by `Intent.ACTION_BATTERY_CHANGED`.
  ///
  /// The mapped broadcast stream is cached per channel instance, so
  /// repeated reads of this getter -- and multiple subscribers -- share
  /// the same underlying [EventChannel.receiveBroadcastStream]
  /// subscription. Without that caching, every read would re-register
  /// the binary messenger handler and silence earlier subscribers.
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
    return _onBatteryStateChanged ??=
        (_eventStream ?? _eventChannel.receiveBroadcastStream()).map((
          dynamic stateCode,
        ) {
          if (stateCode is! int) {
            throw Exception(
              'Invalid battery state type: ${stateCode.runtimeType}',
            );
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
        });
  }
}
