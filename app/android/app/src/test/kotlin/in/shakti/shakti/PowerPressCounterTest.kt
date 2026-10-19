package `in`.shakti.shakti

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PowerPressCounterTest {

    @Test
    fun threePressesWithinWindowTrigger() {
        val c = PowerPressCounter()
        assertFalse(c.onPress(0))
        assertFalse(c.onPress(400))
        assertTrue(c.onPress(800))
        assertEquals(0, c.pending)
    }

    @Test
    fun exactlyAtWindowBoundaryStillCounts() {
        val c = PowerPressCounter()
        c.onPress(0)
        c.onPress(600)
        assertTrue(c.onPress(1200))
    }

    @Test
    fun pressesSpreadTooFarDoNotTrigger() {
        val c = PowerPressCounter()
        assertFalse(c.onPress(0))
        assertFalse(c.onPress(700))
        assertFalse(c.onPress(1300)) // first press expired
        assertEquals(2, c.pending)
        assertTrue(c.onPress(1500))
    }

    @Test
    fun resetsAfterTriggerSoFourthPressDoesNotRetrigger() {
        val c = PowerPressCounter()
        c.onPress(0); c.onPress(100)
        assertTrue(c.onPress(200))
        assertFalse(c.onPress(300))
        assertFalse(c.onPress(400))
        assertTrue(c.onPress(500))
    }

    @Test
    fun customRequiredCount() {
        val c = PowerPressCounter(required = 5, windowMs = 2000)
        repeat(4) { assertFalse(c.onPress(it * 100L)) }
        assertTrue(c.onPress(500))
    }

    @Test
    fun backwardsClockClearsHistory() {
        val c = PowerPressCounter()
        c.onPress(5000); c.onPress(5100)
        assertFalse(c.onPress(10))
        assertEquals(1, c.pending)
    }

    @Test
    fun explicitReset() {
        val c = PowerPressCounter()
        c.onPress(0); c.onPress(100)
        c.reset()
        assertFalse(c.onPress(200))
    }
}
