package com.nllewellyn.battery_status

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

/// Flutter plugin that registers battery monitoring EventChannels.
///
/// Provides three streams to the Dart side:
/// - `com.nllewellyn.battery_status/battery_level` -- battery percentage (0-100)
/// - `com.nllewellyn.battery_status/battery_state` -- charging state enum code (0-4)
/// - `com.nllewellyn.battery_status/battery_save_mode` -- battery saver on/off
class BatteryStatusPlugin : FlutterPlugin {

    private var batteryLevelChannel: EventChannel? = null
    private var batteryStateChannel: EventChannel? = null
    private var batterySaveModeChannel: EventChannel? = null

    private var batteryLevelHandler: BatteryLevelStreamHandler? = null
    private var batteryStateHandler: BatteryStateStreamHandler? = null
    private var batterySaveModeHandler: BatterySaveModeStreamHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = binding.binaryMessenger
        val context = binding.applicationContext

        batteryLevelHandler = BatteryLevelStreamHandler(context)
        batteryLevelChannel = EventChannel(
            messenger,
            "com.nllewellyn.battery_status/battery_level"
        ).also {
            it.setStreamHandler(batteryLevelHandler)
        }

        batteryStateHandler = BatteryStateStreamHandler(context)
        batteryStateChannel = EventChannel(
            messenger,
            "com.nllewellyn.battery_status/battery_state"
        ).also {
            it.setStreamHandler(batteryStateHandler)
        }

        batterySaveModeHandler = BatterySaveModeStreamHandler(context)
        batterySaveModeChannel = EventChannel(
            messenger,
            "com.nllewellyn.battery_status/battery_save_mode"
        ).also {
            it.setStreamHandler(batterySaveModeHandler)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        batteryLevelChannel?.setStreamHandler(null)
        batteryStateChannel?.setStreamHandler(null)
        batterySaveModeChannel?.setStreamHandler(null)

        batteryLevelChannel = null
        batteryStateChannel = null
        batterySaveModeChannel = null

        batteryLevelHandler = null
        batteryStateHandler = null
        batterySaveModeHandler = null
    }
}
