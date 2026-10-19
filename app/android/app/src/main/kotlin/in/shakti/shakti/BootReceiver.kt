package `in`.shakti.shakti

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restarts GuardService after boot if the user had enabled it. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED && action != Intent.ACTION_LOCKED_BOOT_COMPLETED) return
        // Before first unlock only device-protected storage is readable; skip then,
        // BOOT_COMPLETED follows after unlock.
        val prefs = try {
            context.getSharedPreferences(TriggerBus.PREFS, Context.MODE_PRIVATE)
        } catch (_: IllegalStateException) {
            return
        }
        if (prefs.getBoolean(TriggerBus.PREF_GUARD_ENABLED, false)) {
            GuardService.start(context)
        }
    }
}
