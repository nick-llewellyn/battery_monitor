import 'dart:async';

import 'package:battery_monitor/battery_monitor.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatterySaveModeChannel', () {
    late StreamController<dynamic> controller;
    late BatterySaveModeChannel channel;

    setUp(() {
      controller = StreamController<dynamic>.broadcast();
      channel = BatterySaveModeChannel(eventStream: controller.stream);
    });

    tearDown(() {
      controller.close();
    });

    test('emits true when save mode enabled', () async {
      final values = <bool>[];
      final sub = channel.onBatterySaveModeChanged.listen(values.add);

      controller.add(true);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([true]);
      await sub.cancel();
    });

    test('emits false when save mode disabled', () async {
      final values = <bool>[];
      final sub = channel.onBatterySaveModeChanged.listen(values.add);

      controller.add(false);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([false]);
      await sub.cancel();
    });

    test('emits multiple toggles in order', () async {
      final values = <bool>[];
      final sub = channel.onBatterySaveModeChanged.listen(values.add);

      controller
        ..add(false)
        ..add(true)
        ..add(false);
      await Future<void>.delayed(Duration.zero);

      check(values).deepEquals([false, true, false]);
      await sub.cancel();
    });

    test('throws on non-bool type', () async {
      Object? caughtError;
      final sub = channel.onBatterySaveModeChanged.listen(
        (_) {},
        onError: (Object error) {
          caughtError = error;
        },
      );

      controller.add(1);
      await Future<void>.delayed(Duration.zero);

      check(caughtError).isA<Exception>();
      await sub.cancel();
    });

    test(
      'caches mapped stream so multiple listeners share one source',
      () async {
        check(
          identical(
            channel.onBatterySaveModeChanged,
            channel.onBatterySaveModeChanged,
          ),
        ).isTrue();

        final first = <bool>[];
        final second = <bool>[];
        final subA = channel.onBatterySaveModeChanged.listen(first.add);
        final subB = channel.onBatterySaveModeChanged.listen(second.add);

        controller
          ..add(true)
          ..add(false);
        await Future<void>.delayed(Duration.zero);

        check(first).deepEquals([true, false]);
        check(second).deepEquals([true, false]);
        await subA.cancel();
        await subB.cancel();
      },
    );
  });

  group('BatterySaveModeChannel platform path', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('shares mapped stream across independent instances', () {
      final a = BatterySaveModeChannel();
      final b = BatterySaveModeChannel();

      check(
        identical(a.onBatterySaveModeChanged, b.onBatterySaveModeChanged),
      ).isTrue();
    });
  });
}
