import 'dart:developer' as developer;

import 'package:battery_monitor/src/battery_provider.dart';
import 'package:battery_monitor/src/models/battery_info.dart';
import 'package:signals/signals.dart';

/// Composes the three reactive signals on a [BatteryProvider] into a
/// single [Signal]<[BatteryInfo]?> for convenient consumption.
///
/// The compose step runs inside a `signals` `effect` so the
/// [batteryInfo] signal recomputes any time the underlying provider's
/// `batteryLevel`, `chargingState`, or `batterySaveMode` changes.
///
/// Always call [dispose] to release the underlying provider's
/// resources.
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

  /// Latest [BatteryInfo] snapshot, recomputed whenever any of the
  /// underlying signals change. `null` only before the first effect
  /// run, which fires synchronously inside the constructor.
  final Signal<BatteryInfo?> batteryInfo = signal<BatteryInfo?>(null);

  void _initialize() {
    effect(() {
      final level = _provider.batteryLevel.value;
      final state = _provider.chargingState.value;
      final saveMode = _provider.batterySaveMode.value;

      developer.log(
        'Battery update: level=$level, state=$state, saveMode=$saveMode',
        name: 'BatteryState',
      );

      batteryInfo.value = BatteryInfo(
        level: level,
        chargingState: state,
        isInBatterySaveMode: saveMode,
      );
    });
  }

  /// Disposes the underlying provider. Idempotent at the provider
  /// level.
  void dispose() {
    _provider.dispose();
  }
}
