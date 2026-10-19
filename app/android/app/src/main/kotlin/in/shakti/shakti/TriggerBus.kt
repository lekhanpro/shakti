package `in`.shakti.shakti

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.EventChannel

/**
 * Shared plumbing for native SOS triggers. Wire strings must equal
 * `TriggerSource.wire` in lib/domain/entities/incident.dart.
 */
object TriggerBus {
    const val TRIPLE_POWER = "TRIPLE_POWER"
    const val VOLUME_TRIPLE = "VOLUME_TRIPLE"

    const val EXTRA_TRIGGER = "shakti_trigger"
    const val PREFS = "shakti_guard"
    const val PREF_GUARD_ENABLED = "guard_enabled"

    const val SOS_CHANNEL_ID = "shakti_sos"
    private const val SOS_NOTIFICATION_ID = 4102
    private const val TAG = "ShaktiTrigger"

    private val main = Handler(Looper.getMainLooper())

    /** Set by MainActivity while the Flutter EventChannel has a listener. */
    @Volatile
    var eventSink: EventChannel.EventSink? = null

    /** Set by MainActivity while it is resumed (foreground). */
    @Volatile
    var activityInForeground: Boolean = false

    fun isEngineListening(): Boolean = eventSink != null

    /**
     * Delivers a trigger: haptic tick, Flutter event (if attached), and brings the
     * app to the front so the countdown is visible even from the lock screen.
     */
    fun dispatch(context: Context, wire: String) {
        val app = context.applicationContext
        vibrateDiscreet(app)
        val delivered = emitToFlutter(wire)
        // If Flutter received the event and the UI is visible, no need to relaunch.
        if (delivered && activityInForeground) return
        // When delivered to Flutter, launch without the extra so it is not handled twice.
        launchApp(app, if (delivered) null else wire)
    }

    private fun emitToFlutter(wire: String): Boolean {
        val sink = eventSink ?: return false
        main.post {
            try {
                sink.success(wire)
            } catch (e: Exception) {
                Log.w(TAG, "event sink failed", e)
            }
        }
        return true
    }

    private fun launchApp(context: Context, wire: String?) {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            if (wire != null) putExtra(EXTRA_TRIGGER, wire)
            putExtra(MainActivity.EXTRA_WAKE, true)
        }
        // Android 14+ blocks most background activity starts; a full-screen-intent
        // notification is the sanctioned path. Before that, try a direct start first.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                context.startActivity(intent)
                return
            } catch (e: Exception) {
                Log.w(TAG, "direct activity start failed, using notification", e)
            }
        }
        postFullScreenNotification(context, intent)
    }

    private fun postFullScreenNotification(context: Context, intent: Intent) {
        ensureSosChannel(context)
        val pi = PendingIntent.getActivity(
            context, 7, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val n = NotificationCompat.Builder(context, SOS_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_shakti)
            .setContentTitle(context.getString(R.string.sos_notification_title))
            .setContentText(context.getString(R.string.sos_notification_text))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pi)
            .setFullScreenIntent(pi, true)
            .setTimeoutAfter(60_000)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(SOS_NOTIFICATION_ID, n)
        } catch (e: SecurityException) {
            Log.w(TAG, "notification permission missing", e)
        }
    }

    fun cancelSosNotification(context: Context) {
        NotificationManagerCompat.from(context).cancel(SOS_NOTIFICATION_ID)
    }

    private fun ensureSosChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java) ?: return
        if (nm.getNotificationChannel(SOS_CHANNEL_ID) != null) return
        val ch = NotificationChannel(
            SOS_CHANNEL_ID,
            context.getString(R.string.sos_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = context.getString(R.string.sos_channel_description)
            setSound(null, null) // discreet: no ringtone
            enableVibration(false)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        nm.createNotificationChannel(ch)
    }

    @Suppress("DEPRECATION")
    private fun vibrateDiscreet(context: Context) {
        try {
            val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
            if (vibrator == null || !vibrator.hasVibrator()) return
            val pattern = longArrayOf(0, 80, 120, 80) // 2 x 80 ms
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                vibrator.vibrate(pattern, -1)
            }
        } catch (e: Exception) {
            Log.w(TAG, "vibrate failed", e)
        }
    }
}
