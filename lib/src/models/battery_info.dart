import 'package:flutter/foundation.dart';

/// Current charging status of the device battery.
enum ChargingState {
  /// Device is plugged in and charging.
  charging,

  /// Device is unplugged and draining.
  discharging,

  /// Battery at 100% while plugged in.
  full,

  /// Device is connected to power but not charging.
  ///
  /// This occurs when the device has a charge limit enabled and the
  /// limit is reached, or when the connected power source is not
  /// powerful enough to charge the battery. Reported on Android only;
  /// iOS collapses this case into [charging] / [full] / [discharging]
  /// at the OS layer.
  connectedNotCharging,

  /// State cannot be determined.
  ///
  /// Returned on the iOS Simulator (no battery hardware) and on
  /// Android when the system reports `BATTERY_STATUS_UNKNOWN` or an
  /// unrecognised status code.
  unknown,
}

/// Composite snapshot of the device battery surfaced by
/// [BatteryProvider] / [BatteryState].
///
/// Carries the battery percentage, the charging state, and the power-
/// save flag in a single immutable record. Equality is structural so
/// instances can be compared directly in tests and in `Signal` /
/// `ValueListenable` consumers.
@immutable
class BatteryInfo {
  /// Creates a battery info instance.
  ///
  /// The `level` invariant (0..100 inclusive) is asserted in debug
  /// builds. Native handlers always emit values in that range; the
  /// assert exists to catch test fakes that drift outside it rather
  /// than to police real data.
  const BatteryInfo({
    required this.level,
    required this.chargingState,
    required this.isInBatterySaveMode,
  }) : assert(
         level >= 0 && level <= 100,
         'Battery level must be between 0 and 100',
       );

  /// Battery charge percentage (0.0..100.0).
  ///
  /// The raw float value from the platform is preserved, allowing the
  /// UI to decide how to display it (e.g., floor, round, or show
  /// decimals). Android always emits an integral percentage; iOS
  /// provides values in 5% increments at the hardware layer (0.05
  /// steps), exposed here without further quantisation.
  final double level;

  /// Current charging status. See [ChargingState].
  final ChargingState chargingState;

  /// Whether the device is in battery save mode.
  ///
  /// Battery save mode (Low Power Mode on iOS, Battery Saver on
  /// Android) is a system feature that reduces power consumption by
  /// limiting background activity, throttling CPU/GPU performance,
  /// and adjusting display settings.
  final bool isInBatterySaveMode;

  /// Returns a copy of this snapshot with the given fields replaced.
  BatteryInfo copyWith({
    double? level,
    ChargingState? chargingState,
    bool? isInBatterySaveMode,
  }) {
    return BatteryInfo(
      level: level ?? this.level,
      chargingState: chargingState ?? this.chargingState,
      isInBatterySaveMode: isInBatterySaveMode ?? this.isInBatterySaveMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatteryInfo &&
        other.level == level &&
        other.chargingState == chargingState &&
        other.isInBatterySaveMode == isInBatterySaveMode;
  }

  @override
  int get hashCode => Object.hash(level, chargingState, isInBatterySaveMode);

  @override
  String toString() =>
      'BatteryInfo(level: $level, chargingState: $chargingState, '
      'isInBatterySaveMode: $isInBatterySaveMode)';
}
