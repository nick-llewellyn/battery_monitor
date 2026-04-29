import 'dart:async';

import 'package:battery_monitor/battery_monitor.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatteryStateChannel', () {
    late StreamController<dynamic> controller;
    late BatteryStateChannel channel;

    setUp(() {
      controller = StreamController<dynamic>.broadcast();
      channel = BatteryStateChannel(eventStream: controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    test('maps state code 1 to charging', () async {
      final values = <ChargingState>[];
      final sub = channel.onBatteryStateChanged.listen(values.add);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([ChargingState.charging]);
      await sub.cancel();
    });

    test('maps state code 2 to discharging', () async {
      final values = <ChargingState>[];
      final sub = channel.onBatteryStateChanged.listen(values.add);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([ChargingState.discharging]);
      await sub.cancel();
    });

    test('maps state code 3 to full', () async {
      final values = <ChargingState>[];
      final sub = channel.onBatteryStateChanged.listen(values.add);

      controller.add(3);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([ChargingState.full]);
      await sub.cancel();
    });

    test('maps state code 4 to connectedNotCharging', () async {
      final values = <ChargingState>[];
      final sub = channel.onBatteryStateChanged.listen(values.add);

      controller.add(4);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([ChargingState.connectedNotCharging]);
      await sub.cancel();
    });

    test('maps state code 0 to unknown', () async {
      final values = <ChargingState>[];
      final sub = channel.onBatteryStateChanged.listen(values.add);

      controller.add(0);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([ChargingState.unknown]);
      await sub.cancel();
    });

    test('maps unrecognized state codes to unknown', () async {
      final values = <ChargingState>[];
      final sub = channel.onBatteryStateChanged.listen(values.add);

      controller.add(99);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([ChargingState.unknown]);
      await sub.cancel();
    });

    test('throws on non-int type', () async {
      Object? caughtError;
      final sub = channel.onBatteryStateChanged.listen(
        (_) {},
        onError: (Object error) {
          caughtError = error;
        },
      );

      controller.add('charging');
      await Future<void>.delayed(Duration.zero);

      check(caughtError).isA<Exception>();
      await sub.cancel();
    });

    test('emits multiple state transitions', () async {
      final values = <ChargingState>[];
      final sub = channel.onBatteryStateChanged.listen(values.add);

      controller
        ..add(2)
        ..add(1)
        ..add(3);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([
        ChargingState.discharging,
        ChargingState.charging,
        ChargingState.full,
      ]);
      await sub.cancel();
    });
  });
}
