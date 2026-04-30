import 'dart:developer' as developer;

import 'package:battery_status/src/battery_provider.dart';
import 'package:battery_status/src/models/battery_info.dart';
import 'package:flutter/foundation.dart';

/// Composes the three [ValueListenable]s on a [BatteryProvider] into a
/// single [ValueListenable]<[BatteryInfo]?> for convenient consumption.
///
/// Listeners on the underlying provider's `batteryLevel`,
/// `chargingState`, and `batterySaveMode` recompute [batteryInfo] on
/// every change. The initial value is composed synchronously in the
/// constructor so [batteryInfo] is non-null from the moment the
/// composer is created.
///
/// Always call [dispose] to release the underlying provider's
/// resources and the internal notifier.
class BatteryState {
  /// Creates a battery state composer for the given [provider].
  ///
  /// The composer takes ownership of [provider] for disposal -- when
  /// [dispose] is called on this object, the provider is disposed
  /// too.
  BatteryState(this._provider) {
    _initialize();
  }

  final BatteryProvider _provider;

  final ValueNotifier<BatteryInfo?> _batteryInfo = ValueNotifier<BatteryInfo?>(
    null,
  );

  /// Latest [BatteryInfo] snapshot, recomputed whenever any of the
  /// underlying [ValueListenable]s change. Initialized synchronously
  /// in the constructor, so the value is non-null immediately after
  /// construction.
  ValueListenable<BatteryInfo?> get batteryInfo => _batteryInfo;

  void _recompute() {
    final level = _provider.batteryLevel.value;
    final state = _provider.chargingState.value;
    final saveMode = _provider.batterySaveMode.value;

    developer.log(
      'Battery update: level=$level, state=$state, saveMode=$saveMode',
      name: 'BatteryState',
    );

    _batteryInfo.value = BatteryInfo(
      level: level,
      chargingState: state,
      isInBatterySaveMode: saveMode,
    );
  }

  void _initialize() {
    _recompute();
    _provider.batteryLevel.addListener(_recompute);
    _provider.chargingState.addListener(_recompute);
    _provider.batterySaveMode.addListener(_recompute);
  }

  /// Detaches the listeners, disposes the internal notifier, and
  /// disposes the underlying provider. Idempotent at the provider
  /// level.
  void dispose() {
    _provider.batteryLevel.removeListener(_recompute);
    _provider.chargingState.removeListener(_recompute);
    _provider.batterySaveMode.removeListener(_recompute);
    _batteryInfo.dispose();
    _provider.dispose();
  }
}
