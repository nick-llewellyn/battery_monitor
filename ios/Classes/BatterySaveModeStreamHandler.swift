import Flutter
import Foundation

/// Stream handler for battery save mode (Low Power Mode) state changes.
///
/// Listens to `NSProcessInfoPowerStateDidChangeNotification` and
/// streams a boolean to Flutter:
/// - `true` when Low Power Mode is enabled
/// - `false` when Low Power Mode is disabled
///
/// Platform support: iOS 9.0+. Earlier versions always observe `false`
/// because Low Power Mode does not exist there.
class BatterySaveModeStreamHandler: NSObject, FlutterStreamHandler {

    /// Event sink used to send battery save mode state changes to Flutter.
    private var eventSink: FlutterEventSink?

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerStateDidChange),
            name: Notification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )

        sendBatterySaveMode()

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )

        eventSink = nil

        return nil
    }

    @objc private func powerStateDidChange(_ notification: Notification) {
        sendBatterySaveMode()
    }

    /// Reads `ProcessInfo.processInfo.isLowPowerModeEnabled` and forwards
    /// the current value to Flutter.
    private func sendBatterySaveMode() {
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        eventSink?(isLowPowerMode)
    }
}
