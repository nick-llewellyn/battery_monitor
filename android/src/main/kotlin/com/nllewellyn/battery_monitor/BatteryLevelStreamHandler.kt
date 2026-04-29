package com.nllewellyn.battery_monitor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.plugin.common.EventChannel

/**
 * Stream handler for battery level change notifications.
 *
 * Implements EventChannel.StreamHandler to deliver a stream of battery level
 * changes to Flutter. Registers a BroadcastReceiver for
 * Intent.ACTION_BATTERY_CHANGED to receive notifications when the level
 * changes.
 *
 * Emits integer values from 0 to 100 representing the battery percentage,
 * or -1 when the level is unknown.
 *
 * Platform support: all Android versions; ACTION_BATTERY_CHANGED is a sticky
 * broadcast so the initial value is delivered synchronously on subscription.
 */
class BatteryLevelStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    /** Event sink used to send battery level changes to Flutter. */
    private var eventSink: EventChannel.EventSink? = null

    /** Broadcast receiver for battery changes. */
    private var batteryReceiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)

        // Sticky broadcast: passing a null receiver returns the cached intent,
        // giving us an immediate initial value with no wait.
        val stickyIntent = context.registerReceiver(null, filter)
        stickyIntent?.let { intent ->
            sendBatteryLevel(intent)
        }

        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == Intent.ACTION_BATTERY_CHANGED) {
                    sendBatteryLevel(intent)
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
     * Reads EXTRA_LEVEL and EXTRA_SCALE from the battery changed intent,
     * computes the percentage, and forwards it to Flutter.
     */
    private fun sendBatteryLevel(intent: Intent) {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)

        val percentage = if (level >= 0 && scale > 0) {
            (level * 100) / scale
        } else {
            -1
        }

        eventSink?.success(percentage)
    }
}
