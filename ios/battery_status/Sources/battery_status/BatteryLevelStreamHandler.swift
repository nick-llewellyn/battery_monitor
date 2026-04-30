import Flutter
import UIKit

/// Stream handler for battery level change notifications.
///
/// Listens to `UIDeviceBatteryLevelDidChangeNotification` and streams
/// battery level changes (0..100) to Flutter via EventChannel. Event-
/// driven; the notification fires on every 1% battery level change
/// (iOS 8+).
class BatteryLevelStreamHandler: NSObject, FlutterStreamHandler {
    /// Event sink for sending battery level updates to Flutter.
    private var eventSink: FlutterEventSink?

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events

        // Required: UIDevice.batteryLevel and the notification only deliver
        // values once monitoring is enabled.
        UIDevice.current.isBatteryMonitoringEnabled = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )

        sendBatteryLevel()

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )

        self.eventSink = nil

        return nil
    }

    @objc private func batteryLevelDidChange(notification: Notification) {
        sendBatteryLevel()
    }

    /// Reads `UIDevice.current.batteryLevel` (0.0..1.0, or -1.0 if
    /// unknown) and forwards a percentage in 0.0..100.0 to Flutter.
    ///
    /// iOS hardware/OS reports battery level in 5% increments, so the
    /// emitted percentage will be a multiple of 5 (e.g., 70.0, 75.0).
    /// Unknown values (Simulator, monitoring disabled) are dropped
    /// rather than forwarded to keep the consumer-facing stream
    /// well-typed.
    private func sendBatteryLevel() {
        let batteryLevel = UIDevice.current.batteryLevel

        if batteryLevel >= 0 {
            let percentage = Double(batteryLevel * 100)
            eventSink?(percentage)
        }
    }
}
