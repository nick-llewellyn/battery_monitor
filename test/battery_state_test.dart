import 'dart:async';

import 'package:battery_monitor/battery_monitor.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_event_channel.dart';

void main() {
  group('BatteryState', () {
    late StreamController<dynamic> levelController;
    late StreamController<dynamic> stateController;
    late StreamController<dynamic> saveModeController;
    late BatteryProvider provider;
    late BatteryState batteryState;

    setUp(() {
      final fakes = createFakeChannels();
      levelController = fakes.levelController;
      stateController = fakes.stateController;
      saveModeController = fakes.saveModeController;
      provider = BatteryProvider(
        batteryLevelChannel: fakes.levelChannel,
        batteryStateChannel: fakes.stateChannel,
        batterySaveModeChannel: fakes.saveModeChannel,
      );
      batteryState = BatteryState(provider);
    });

    tearDown(() {
      batteryState.dispose();
      levelController.close();
      stateController.close();
      saveModeController.close();
    });

    test('batteryInfo starts with default values via effect', () {
      final info = batteryState.batteryInfo.value;

      check(info).isNotNull();
      check(info!.level).equals(0);
      check(info.chargingState).equals(ChargingState.unknown);
      check(info.isInBatterySaveMode).equals(false);
    });

    test('updates batteryInfo when level changes', () async {
      levelController.add(75);
      await Future<void>.delayed(Duration.zero);

      final info = batteryState.batteryInfo.value;
      check(info).isNotNull();
      check(info!.level).equals(75);
    });

    test('updates batteryInfo when charging state changes', () async {
      stateController.add(1);
      await Future<void>.delayed(Duration.zero);

      final info = batteryState.batteryInfo.value;
      check(info).isNotNull();
      check(info!.chargingState).equals(ChargingState.charging);
    });

    test('updates batteryInfo when save mode changes', () async {
      saveModeController.add(true);
      await Future<void>.delayed(Duration.zero);

      final info = batteryState.batteryInfo.value;
      check(info).isNotNull();
      check(info!.isInBatterySaveMode).equals(true);
    });

    test('composes all three values into BatteryInfo', () async {
      levelController.add(95);
      stateController.add(3);
      saveModeController.add(false);
      await Future<void>.delayed(Duration.zero);

      final info = batteryState.batteryInfo.value;
      check(info).isNotNull();
      check(info!.level).equals(95);
      check(info.chargingState).equals(ChargingState.full);
      check(info.isInBatterySaveMode).equals(false);
    });

    test('batteryInfo signal is reactive to multiple updates', () async {
      levelController.add(50);
      await Future<void>.delayed(Duration.zero);
      check(batteryState.batteryInfo.value!.level).equals(50);

      levelController.add(60);
      await Future<void>.delayed(Duration.zero);
      check(batteryState.batteryInfo.value!.level).equals(60);
    });
  });
}
