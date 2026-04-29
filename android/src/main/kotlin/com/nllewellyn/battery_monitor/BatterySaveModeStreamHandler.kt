package com.nllewellyn.battery_monitor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager
import io.flutter.plugin.common.EventChannel

/**
 * Stream handler for battery save mode (Battery Saver) state changes.
 *
 * Implements EventChannel.StreamHandler to deliver a boolean stream of
 * Battery Saver state changes to Flutter. Registers a BroadcastReceiver for
 * PowerManager.ACTION_POWER_SAVE_MODE_CHANGED.
 *
 * Emits `true` when Battery Saver is enabled and `false` when it is
 * disabled. An initial state is sent immediately on subscription.
 *
 * Platform support: Android API 21+ (Lollipop). Earlier versions are not
 * supported because the API does not exist.
 */
class BatterySaveModeStreamHandler(private val context: Context) : EventChannel.StreamHandler {

    /** Event sink used to send battery save mode state changes to Flutter. */
    private var eventSink: EventChannel.EventSink? = null

    /** Broadcast receiver for power save mode changes. */
    private var powerSaveModeReceiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        powerSaveModeReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action == PowerManager.ACTION_POWER_SAVE_MODE_CHANGED) {
                    sendBatterySaveMode()
                }
            }
        }

        val filter = IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        context.registerReceiver(powerSaveModeReceiver, filter)

        sendBatterySaveMode()
    }

    override fun onCancel(arguments: Any?) {
        powerSaveModeReceiver?.let {
            context.unregisterReceiver(it)
        }
        powerSaveModeReceiver = null
        eventSink = null
    }

    /**
     * Queries `PowerManager.isPowerSaveMode` and forwards the current value
     * to Flutter.
     */
    private fun sendBatterySaveMode() {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val isPowerSaveMode = powerManager.isPowerSaveMode
        eventSink?.success(isPowerSaveMode)
    }
}
