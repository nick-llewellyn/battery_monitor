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
    /// Reporting granularity is OS-version dependent and undocumented.
    /// Apple Developer Technical Support has confirmed that on some
    /// iOS versions the value is rounded to 1% and on others to 5%,
    /// and that no other public API can change this rounding. In
    /// practice iOS 8.1..16 reported 1% steps, and iOS 17+ regressed
    /// to 5% steps as an anti-fingerprinting measure. The handler
    /// forwards whatever resolution the OS provides without further
    /// quantisation. Unknown values (Simulator, monitoring disabled)
    /// are dropped rather than forwarded to keep the consumer-facing
    /// stream well-typed.
    ///
    /// The `eventSink` invocation is hopped to the main queue. Apple
    /// posts `UIDevice.batteryLevelDidChangeNotification` on the main
    /// queue today, but does not guarantee it; aligning every handler
    /// in this plugin on `DispatchQueue.main.async` makes the platform-
    /// thread invariant explicit and matches the save-mode handler,
    /// whose source notification is documented as background-delivered.
    private func sendBatteryLevel() {
        let batteryLevel = UIDevice.current.batteryLevel

        if batteryLevel >= 0 {
            let percentage = Double(batteryLevel * 100)
            DispatchQueue.main.async { [weak self] in
                self?.eventSink?(percentage)
            }
        }
    }
}
