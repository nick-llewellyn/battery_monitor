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
 * Emits integer values from 0 to 100 representing the battery percentage.
 * When the level is unknown (EXTRA_LEVEL or EXTRA_SCALE missing/invalid),
 * the value is dropped rather than forwarded -- matching the iOS handler --
 * so the consumer-facing stream stays well-typed and the Dart-side
 * `BatteryInfo` 0..100 invariant holds.
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
     * computes the percentage, and forwards it to Flutter. Unknown values
     * (negative `EXTRA_LEVEL` or non-positive `EXTRA_SCALE`) are dropped
     * silently -- the consumer-facing stream only carries 0..100.
     */
    private fun sendBatteryLevel(intent: Intent) {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)

        if (level < 0 || scale <= 0) {
            return
        }

        val percentage = (level * 100) / scale
        eventSink?.success(percentage)
    }
}
