package `in`.shakti.shakti

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/**
 * Foreground service (type=location) that listens for SCREEN_OFF/SCREEN_ON toggles.
 * Three toggles within 1.2 s (i.e. three power presses) raise TRIPLE_POWER.
 */
class GuardService : Service() {

    private val counter = PowerPressCounter(required = 3, windowMs = 1200L)
    private var receiverRegistered = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF, Intent.ACTION_SCREEN_ON -> {
                    if (counter.onPress(SystemClock.elapsedRealtime())) {
                        TriggerBus.dispatch(context, TriggerBus.TRIPLE_POWER)
                    }
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelfSafely()
            return START_NOT_STICKY
        }
        if (!goForeground()) {
            stopSelf()
            return START_NOT_STICKY
        }
        registerScreenReceiver()
        return START_STICKY
    }

    private fun goForeground(): Boolean {
        ensureGuardChannel()
        val notification = buildNotification()
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        } else {
            0
        }
        return try {
            ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, type)
            true
        } catch (e: Exception) {
            // API 34+: SecurityException if location permission is not granted;
            // API 31+: ForegroundServiceStartNotAllowedException from background.
            Log.w(TAG, "startForeground failed", e)
            false
        }
    }

    private fun buildNotification() = NotificationCompat.Builder(this, GUARD_CHANNEL_ID)
        .setSmallIcon(R.drawable.ic_stat_shakti)
        .setContentTitle(getString(R.string.guard_notification_title))
        .setContentText(getString(R.string.guard_notification_text))
        .setOngoing(true)
        .setShowWhen(false)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .setCategory(NotificationCompat.CATEGORY_SERVICE)
        .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        .setContentIntent(
            PendingIntent.getActivity(
                this, 0,
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
        .build()

    private fun ensureGuardChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NotificationManager::class.java) ?: return
        if (nm.getNotificationChannel(GUARD_CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                GUARD_CHANNEL_ID,
                getString(R.string.guard_channel_name),
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = getString(R.string.guard_channel_description)
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            },
        )
    }

    private fun registerScreenReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        // Protected system broadcasts; NOT_EXPORTED is correct and required on API 34+.
        ContextCompat.registerReceiver(this, screenReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
        receiverRegistered = true
    }

    private fun stopSelfSafely() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        if (receiverRegistered) {
            try {
                unregisterReceiver(screenReceiver)
            } catch (_: IllegalArgumentException) {
            }
            receiverRegistered = false
        }
        running = false
        super.onDestroy()
    }

    companion object {
        private const val TAG = "ShaktiGuard"
        const val GUARD_CHANNEL_ID = "shakti_guard"
        private const val NOTIFICATION_ID = 4101
        const val ACTION_STOP = "in.shakti.shakti.action.STOP_GUARD"

        @Volatile
        var running: Boolean = false
            private set

        fun start(context: Context) {
            val i = Intent(context, GuardService::class.java)
            try {
                ContextCompat.startForegroundService(context, i)
            } catch (e: Exception) {
                Log.w(TAG, "could not start guard service", e)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, GuardService::class.java))
        }
    }
}
