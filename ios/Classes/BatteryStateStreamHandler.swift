import Flutter
import UIKit

/// Stream handler for battery charging state change notifications.
///
/// Listens to `UIDevice.batteryStateDidChangeNotification` and streams
/// integer codes representing the current charging state to Flutter.
///
/// Emitted codes (mirrored on the Dart side as `ChargingState`):
/// - 0 = unknown
/// - 1 = charging
/// - 2 = discharging (unplugged)
/// - 3 = full
class BatteryStateStreamHandler: NSObject, FlutterStreamHandler {

    /// Event sink used to send battery state changes to Flutter.
    private var eventSink: FlutterEventSink?

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events

        // Required: UIDevice.batteryState and the notification only
        // deliver values once monitoring is enabled.
        UIDevice.current.isBatteryMonitoringEnabled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateDidChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )

        sendBatteryState()

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )

        // Battery monitoring is left enabled because the level handler
        // may still need it.
        eventSink = nil

        return nil
    }

    @objc private func batteryStateDidChange(_ notification: Notification) {
        sendBatteryState()
    }

    /// Maps `UIDevice.current.batteryState` to the integer codes the
    /// Dart side translates back into the `ChargingState` enum.
    private func sendBatteryState() {
        let state = UIDevice.current.batteryState

        let stateCode: Int
        switch state {
        case .charging:
            stateCode = 1
        case .full:
            stateCode = 3
        case .unplugged:
            stateCode = 2
        case .unknown:
            stateCode = 0
        @unknown default:
            stateCode = 0
        }

        eventSink?(stateCode)
    }
}
