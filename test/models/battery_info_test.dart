import 'package:battery_status/battery_status.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChargingState', () {
    test('has all expected values', () {
      check(ChargingState.values).length.equals(5);
      check(ChargingState.values).contains(ChargingState.charging);
      check(ChargingState.values).contains(ChargingState.discharging);
      check(ChargingState.values).contains(ChargingState.full);
      check(ChargingState.values).contains(ChargingState.connectedNotCharging);
      check(ChargingState.values).contains(ChargingState.unknown);
    });
  });

  group('BatteryInfo', () {
    test('creates with required parameters', () {
      const info = BatteryInfo(
        level: 75,
        chargingState: ChargingState.charging,
        isInBatterySaveMode: false,
      );

      check(info.level).equals(75);
      check(info.chargingState).equals(ChargingState.charging);
      check(info.isInBatterySaveMode).equals(false);
    });

    test('supports equality', () {
      const a = BatteryInfo(
        level: 50,
        chargingState: ChargingState.discharging,
        isInBatterySaveMode: true,
      );
      const b = BatteryInfo(
        level: 50,
        chargingState: ChargingState.discharging,
        isInBatterySaveMode: true,
      );

      check(a).equals(b);
      check(a.hashCode).equals(b.hashCode);
    });

    test('detects inequality on level', () {
      const a = BatteryInfo(
        level: 50,
        chargingState: ChargingState.charging,
        isInBatterySaveMode: false,
      );
      const b = BatteryInfo(
        level: 75,
        chargingState: ChargingState.charging,
        isInBatterySaveMode: false,
      );

      check(a).not((it) => it.equals(b));
    });

    test('detects inequality on chargingState', () {
      const a = BatteryInfo(
        level: 50,
        chargingState: ChargingState.charging,
        isInBatterySaveMode: false,
      );
      const b = BatteryInfo(
        level: 50,
        chargingState: ChargingState.full,
        isInBatterySaveMode: false,
      );

      check(a).not((it) => it.equals(b));
    });

    test('detects inequality on isInBatterySaveMode', () {
      const a = BatteryInfo(
        level: 50,
        chargingState: ChargingState.charging,
        isInBatterySaveMode: false,
      );
      const b = BatteryInfo(
        level: 50,
        chargingState: ChargingState.charging,
        isInBatterySaveMode: true,
      );

      check(a).not((it) => it.equals(b));
    });

    test('copyWith creates modified copy', () {
      const original = BatteryInfo(
        level: 50,
        chargingState: ChargingState.discharging,
        isInBatterySaveMode: false,
      );

      final modified = original.copyWith(
        level: 100,
        chargingState: ChargingState.full,
      );

      check(modified.level).equals(100);
      check(modified.chargingState).equals(ChargingState.full);
      check(modified.isInBatterySaveMode).equals(false);
    });

    test('copyWith preserves unchanged fields', () {
      const original = BatteryInfo(
        level: 80,
        chargingState: ChargingState.charging,
        isInBatterySaveMode: true,
      );

      final modified = original.copyWith(level: 90);

      check(modified.level).equals(90);
      check(modified.chargingState).equals(ChargingState.charging);
      check(modified.isInBatterySaveMode).equals(true);
    });

    test('accepts boundary level values', () {
      const zero = BatteryInfo(
        level: 0,
        chargingState: ChargingState.discharging,
        isInBatterySaveMode: false,
      );
      const full = BatteryInfo(
        level: 100,
        chargingState: ChargingState.full,
        isInBatterySaveMode: false,
      );

      check(zero.level).equals(0);
      check(full.level).equals(100);
    });

    test('accepts fractional level values', () {
      const info = BatteryInfo(
        level: 42.5,
        chargingState: ChargingState.charging,
        isInBatterySaveMode: false,
      );

      check(info.level).equals(42.5);
    });
  });
}
