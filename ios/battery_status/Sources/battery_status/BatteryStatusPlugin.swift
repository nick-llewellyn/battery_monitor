import Flutter

/// Flutter plugin that registers battery monitoring EventChannels.
///
/// Provides three streams to the Dart side:
/// - `com.nllewellyn.battery_status/battery_level` -- battery percentage (0-100)
/// - `com.nllewellyn.battery_status/battery_state` -- charging state enum code (0-4)
/// - `com.nllewellyn.battery_status/battery_save_mode` -- Low Power Mode on/off
public class BatteryStatusPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()

        let batteryLevelChannel = FlutterEventChannel(
            name: "com.nllewellyn.battery_status/battery_level",
            binaryMessenger: messenger
        )
        batteryLevelChannel.setStreamHandler(BatteryLevelStreamHandler())

        let batteryStateChannel = FlutterEventChannel(
            name: "com.nllewellyn.battery_status/battery_state",
            binaryMessenger: messenger
        )
        batteryStateChannel.setStreamHandler(BatteryStateStreamHandler())

        let batterySaveModeChannel = FlutterEventChannel(
            name: "com.nllewellyn.battery_status/battery_save_mode",
            binaryMessenger: messenger
        )
        batterySaveModeChannel.setStreamHandler(BatterySaveModeStreamHandler())
    }
}
