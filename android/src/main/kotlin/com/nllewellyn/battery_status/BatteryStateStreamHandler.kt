package com.nllewellyn.battery_status

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.plugin.common.EventChannel

/**
 * Stream handler for battery charging state change notifications.
 *
 * Implements EventChannel.StreamHandler to deliver a stream of charging
 * state codes to Flutter. Registers a BroadcastReceiver for
 * Intent.ACTION_BATTERY_CHANGED.
 *
 * Emits integer codes mapped to the Dart `ChargingState` enum:
 * - 0 = unknown
 * - 1 = charging
 * - 2 = discharging
 * - 3 = full
 * - 4 = connectedNotCharging
 *
 * Platform support: all Android versions; ACTION_BATTERY_CHANGED is a sticky
 * broadcast so the initial state is delivered synchronously on subscription.
 */
class BatteryStateStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    /** Event sink used to send battery state changes to Flutter. */
    private var eventSink: EventChannel.EventSink? = null

    /** Broadcast receiver for battery changes. */
    private var batteryReceiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)

        val stickyIntent = context.registerReceiver(null, filter)
        stickyIntent?.let { intent ->
            sendBatteryState(intent)
        }

        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == Intent.ACTION_BATTERY_CHANGED) {
                    sendBatteryState(intent)
                }
            }
        }

        context.registerReceiver(batteryReceiver, filter)
    }

    override fun onCancel(arguments: Any?) {
        batteryReceiver?.let {
            context.unregisterReceiver(it)
        }
        batteryReceiver = null
        eventSink = null
    }

    /**
     * Reads EXTRA_STATUS from the battery changed intent and maps it to
     * the integer codes the Dart side translates back into the
     * `ChargingState` enum.
     */
    private fun sendBatteryState(intent: Intent) {
        val status = intent.getIntExtra(
            BatteryManager.EXTRA_STATUS,
            BatteryManager.BATTERY_STATUS_UNKNOWN
        )

        val stateCode = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> 1
            BatteryManager.BATTERY_STATUS_FULL -> 3
            BatteryManager.BATTERY_STATUS_DISCHARGING -> 2
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> 4
            else -> 0
        }

        eventSink?.success(stateCode)
    }
}
