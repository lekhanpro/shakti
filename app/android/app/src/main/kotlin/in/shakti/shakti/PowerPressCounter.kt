package `in`.shakti.shakti

/**
 * Counts presses (screen on/off toggles or key presses) and reports when
 * [required] of them fall inside a sliding [windowMs] window.
 *
 * Pure Kotlin so it can be unit tested on the JVM. Timestamps are supplied by
 * the caller (use SystemClock.elapsedRealtime() on device).
 */
class PowerPressCounter(
    private val required: Int = 3,
    private val windowMs: Long = 1200L,
) {
    init {
        require(required >= 1) { "required must be >= 1" }
        require(windowMs > 0) { "windowMs must be > 0" }
    }

    private val presses = ArrayDeque<Long>()

    /** Records a press at [nowMs]. Returns true (and resets) when the gesture completes. */
    @Synchronized
    fun onPress(nowMs: Long): Boolean {
        // A clock that jumps backwards invalidates history.
        if (presses.isNotEmpty() && nowMs < presses.last()) presses.clear()
        presses.addLast(nowMs)
        while (presses.isNotEmpty() && nowMs - presses.first() > windowMs) {
            presses.removeFirst()
        }
        if (presses.size >= required) {
            presses.clear()
            return true
        }
        return false
    }

    @Synchronized
    fun reset() = presses.clear()

    @get:Synchronized
    val pending: Int
        get() = presses.size
}
