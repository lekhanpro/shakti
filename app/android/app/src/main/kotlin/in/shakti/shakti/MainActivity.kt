package `in`.shakti.shakti

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterFragmentActivity (required by local_auth).
 *
 * MethodChannel "shakti/guard":
 *   startGuard, stopGuard, setSecureScreen(bool), isAccessibilityEnabled -> bool,
 *   openAccessibilitySettings, consumeLaunchTrigger -> String?
 * EventChannel "shakti/guard/events": trigger wire strings (TRIPLE_POWER, VOLUME_TRIPLE).
 */
class MainActivity : FlutterFragmentActivity() {

    /** Trigger carried by the launching intent that Flutter has not consumed yet. */
    private var pendingTrigger: String? = null
    private var eventsChannel: EventChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Evidence and contacts must not appear in screenshots or recents by default.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        handleTriggerIntent(intent, fromNewIntent = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleTriggerIntent(intent, fromNewIntent = true)
    }

    override fun onResume() {
        super.onResume()
        TriggerBus.activityInForeground = true
    }

    override fun onPause() {
        TriggerBus.activityInForeground = false
        super.onPause()
    }

    private fun handleTriggerIntent(intent: Intent?, fromNewIntent: Boolean) {
        if (intent == null) return
        val wire = intent.getStringExtra(TriggerBus.EXTRA_TRIGGER)
        val wake = intent.getBooleanExtra(EXTRA_WAKE, false)
        if (wire == null && !wake) return
        intent.removeExtra(TriggerBus.EXTRA_TRIGGER)
        intent.removeExtra(EXTRA_WAKE)
        TriggerBus.cancelSosNotification(this)
        showOverLockScreen()
        if (wire == null) return
        // While running, stream it live; otherwise hold until Flutter asks.
        val sink = TriggerBus.eventSink
        if (fromNewIntent && sink != null) {
            sink.success(wire)
        } else {
            pendingTrigger = wire
        }
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        // The keyguard is intentionally not dismissed: the SOS countdown shows over it.
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startGuard" -> {
                    prefs().edit().putBoolean(TriggerBus.PREF_GUARD_ENABLED, true).apply()
                    GuardService.start(applicationContext)
                    result.success(null)
                }
                "stopGuard" -> {
                    prefs().edit().putBoolean(TriggerBus.PREF_GUARD_ENABLED, false).apply()
                    GuardService.stop(applicationContext)
                    result.success(null)
                }
                "setSecureScreen" -> {
                    val on = call.arguments as? Boolean ?: call.argument<Boolean>("on") ?: true
                    runOnUiThread {
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                }
                "isAccessibilityEnabled" -> result.success(isAccessibilityServiceEnabled())
                "openAccessibilitySettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", e.message, null)
                    }
                }
                "consumeLaunchTrigger" -> {
                    val t = pendingTrigger
                    pendingTrigger = null
                    result.success(t)
                }
                else -> result.notImplemented()
            }
        }

        eventsChannel = EventChannel(messenger, EVENT_CHANNEL).also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    TriggerBus.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    TriggerBus.eventSink = null
                }
            })
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        eventsChannel?.setStreamHandler(null)
        eventsChannel = null
        TriggerBus.eventSink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun prefs() = getSharedPreferences(TriggerBus.PREFS, Context.MODE_PRIVATE)

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = ComponentName(this, ShaktiAccessibilityService::class.java)
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabled)
        for (s in splitter) {
            val cn = ComponentName.unflattenFromString(s) ?: continue
            if (cn == expected) return true
        }
        return false
    }

    companion object {
        const val METHOD_CHANNEL = "shakti/guard"
        const val EVENT_CHANNEL = "shakti/guard/events"
        const val EXTRA_WAKE = "shakti_wake"
    }
}
