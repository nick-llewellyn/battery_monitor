import 'dart:async';

import 'package:battery_monitor/battery_monitor.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatteryLevelChannel', () {
    late StreamController<dynamic> controller;
    late BatteryLevelChannel channel;

    setUp(() {
      controller = StreamController<dynamic>.broadcast();
      channel = BatteryLevelChannel(eventStream: controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    test('emits integer battery levels', () async {
      final values = <int>[];
      final sub = channel.onBatteryLevelChanged.listen(values.add);

      controller.add(85);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([85]);
      await sub.cancel();
    });

    test('converts double values to int', () async {
      final values = <int>[];
      final sub = channel.onBatteryLevelChanged.listen(values.add);

      controller.add(42.7);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([42]);
      await sub.cancel();
    });

    test('emits multiple values in order', () async {
      final values = <int>[];
      final sub = channel.onBatteryLevelChanged.listen(values.add);

      controller
        ..add(100)
        ..add(99)
        ..add(98);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([100, 99, 98]);
      await sub.cancel();
    });

    test('throws on invalid type', () async {
      Object? caughtError;
      final sub = channel.onBatteryLevelChanged.listen(
        (_) {},
        onError: (Object error) {
          caughtError = error;
        },
      );

      controller.add('not_a_number');
      await Future<void>.delayed(Duration.zero);

      check(caughtError).isA<Exception>();
      await sub.cancel();
    });
  });
}
