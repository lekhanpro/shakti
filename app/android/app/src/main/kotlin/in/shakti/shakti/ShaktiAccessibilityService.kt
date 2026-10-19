package `in`.shakti.shakti

import android.accessibilityservice.AccessibilityService
import android.os.SystemClock
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

/**
 * Opt-in accessibility service. Counts VOLUME_DOWN presses (3 within 1.2 s) and
 * raises VOLUME_TRIPLE. Key events are never consumed, so volume still works.
 */
class ShaktiAccessibilityService : AccessibilityService() {

    private val counter = PowerPressCounter(required = 3, windowMs = 1200L)

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN &&
            event.action == KeyEvent.ACTION_DOWN &&
            event.repeatCount == 0
        ) {
            if (counter.onPress(SystemClock.elapsedRealtime())) {
                TriggerBus.dispatch(this, TriggerBus.VOLUME_TRIPLE)
            }
        }
        return false // never consume
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not used: we only read key events.
    }

    override fun onInterrupt() {
        counter.reset()
    }
}
