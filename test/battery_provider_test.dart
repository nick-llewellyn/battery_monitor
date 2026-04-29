import 'dart:async';

import 'package:battery_monitor/battery_monitor.dart';
import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_event_channel.dart';

void main() {
  group('BatteryProvider', () {
    late StreamController<dynamic> levelController;
    late StreamController<dynamic> stateController;
    late StreamController<dynamic> saveModeController;
    late BatteryProvider provider;

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
    });

    tearDown(() {
      provider.dispose();
      levelController.close();
      stateController.close();
      saveModeController.close();
    });

    test('initial signal values are defaults', () {
      check(provider.batteryLevel.value).equals(0);
      check(provider.chargingState.value).equals(ChargingState.unknown);
      check(provider.batterySaveMode.value).equals(false);
    });

    test('updates batteryLevel from channel', () async {
      levelController.add(85);
      await Future<void>.delayed(Duration.zero);

      check(provider.batteryLevel.value).equals(85);
    });

    test('updates chargingState from channel', () async {
      stateController.add(1);
      await Future<void>.delayed(Duration.zero);

      check(provider.chargingState.value).equals(ChargingState.charging);
    });

    test('updates batterySaveMode from channel', () async {
      saveModeController.add(true);
      await Future<void>.delayed(Duration.zero);

      check(provider.batterySaveMode.value).equals(true);
    });

    test('tracks all three channels simultaneously', () async {
      levelController.add(42);
      stateController.add(3);
      saveModeController.add(true);
      await Future<void>.delayed(Duration.zero);

      check(provider.batteryLevel.value).equals(42);
      check(provider.chargingState.value).equals(ChargingState.full);
      check(provider.batterySaveMode.value).equals(true);
    });

    test('records errors from battery level channel', () async {
      levelController.addError(Exception('level failed'));
      await Future<void>.delayed(Duration.zero);

      check(provider.batteryErrors.value).length.equals(1);
      check(
        provider.batteryErrors.value.first.errorType,
      ).equals('Battery Level');
    });

    test('records errors from battery state channel', () async {
      stateController.addError(Exception('state failed'));
      await Future<void>.delayed(Duration.zero);

      check(provider.batteryErrors.value).length.equals(1);
      check(
        provider.batteryErrors.value.first.errorType,
      ).equals('Battery State');
    });

    test('records errors from save mode channel', () async {
      saveModeController.addError(Exception('save mode failed'));
      await Future<void>.delayed(Duration.zero);

      check(provider.batteryErrors.value).length.equals(1);
      check(
        provider.batteryErrors.value.first.errorType,
      ).equals('Battery Save Mode');
    });

    test('keeps at most 10 errors', () async {
      for (var i = 0; i < 15; i++) {
        levelController.addError(Exception('error $i'));
        await Future<void>.delayed(Duration.zero);
      }

      check(provider.batteryErrors.value).length.equals(10);
    });

    test('clearErrors removes all recorded errors', () async {
      levelController.addError(Exception('oops'));
      await Future<void>.delayed(Duration.zero);
      check(provider.batteryErrors.value).isNotEmpty();

      provider.clearErrors();

      check(provider.batteryErrors.value).isEmpty();
    });
  });

  group('BatteryError', () {
    test('toString includes errorType and error', () {
      final error = BatteryError(
        errorType: 'Battery Level',
        error: Exception('test'),
        timestamp: DateTime(2024),
      );

      check(error.toString()).contains('Battery Level');
    });

    test('stores stackTrace when provided', () {
      final trace = StackTrace.current;
      final error = BatteryError(
        errorType: 'Test',
        error: 'failure',
        timestamp: DateTime(2024),
        stackTrace: trace,
      );

      check(error.stackTrace).equals(trace);
    });
  });

  group('multiple BatteryProvider instances on the platform path', () {
    const levelName = 'com.nllewellyn.battery_monitor/battery_level';
    const stateName = 'com.nllewellyn.battery_monitor/battery_state';
    const saveModeName = 'com.nllewellyn.battery_monitor/battery_save_mode';

    late TestDefaultBinaryMessenger messenger;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      Future<dynamic> noop(MethodCall _) async => null;
      messenger.setMockMethodCallHandler(const MethodChannel(levelName), noop);
      messenger.setMockMethodCallHandler(const MethodChannel(stateName), noop);
      messenger.setMockMethodCallHandler(
        const MethodChannel(saveModeName),
        noop,
      );
    });

    tearDownAll(() {
      messenger.setMockMethodCallHandler(const MethodChannel(levelName), null);
      messenger.setMockMethodCallHandler(const MethodChannel(stateName), null);
      messenger.setMockMethodCallHandler(
        const MethodChannel(saveModeName),
        null,
      );
    });

    test('both providers observe a single simulated level event', () async {
      final providerA = BatteryProvider();
      final providerB = BatteryProvider();
      await Future<void>.delayed(Duration.zero);

      final event = const StandardMethodCodec().encodeSuccessEnvelope(75);
      await messenger.handlePlatformMessage(levelName, event, (_) {});
      await Future<void>.delayed(Duration.zero);

      check(providerA.batteryLevel.value).equals(75);
      check(providerB.batteryLevel.value).equals(75);

      providerA.dispose();
      providerB.dispose();
    });
  });
}
