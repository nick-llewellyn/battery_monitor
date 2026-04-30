import 'dart:async';

import 'package:battery_status/battery_status.dart';

/// Creates a set of stream controllers and channel instances for
/// testing.
///
/// Returns a record with the three controllers and three channel
/// instances wired together via dependency injection (no platform
/// channel needed). The controllers are returned so the caller can
/// drive synthetic events and close them in `tearDown`.
({
  StreamController<dynamic> levelController,
  StreamController<dynamic> stateController,
  StreamController<dynamic> saveModeController,
  BatteryLevelChannel levelChannel,
  BatteryStateChannel stateChannel,
  BatterySaveModeChannel saveModeChannel,
})
createFakeChannels() {
  // Controllers are closed by the caller in tearDown.
  // ignore: close_sinks
  final levelController = StreamController<dynamic>.broadcast();
  // ignore: close_sinks
  final stateController = StreamController<dynamic>.broadcast();
  // ignore: close_sinks
  final saveModeController = StreamController<dynamic>.broadcast();

  return (
    levelController: levelController,
    stateController: stateController,
    saveModeController: saveModeController,
    levelChannel: BatteryLevelChannel(eventStream: levelController.stream),
    stateChannel: BatteryStateChannel(eventStream: stateController.stream),
    saveModeChannel: BatterySaveModeChannel(
      eventStream: saveModeController.stream,
    ),
  );
}
