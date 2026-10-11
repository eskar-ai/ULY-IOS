package org.uyghurlatin.keyboard

import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Smoke UI test for the host setup activity.
 * Requires a device or emulator: `./gradlew :app:connectedDebugAndroidTest`
 */
@RunWith(AndroidJUnit4::class)
class HostMainActivityTest {
    @get:Rule
    val activityRule = ActivityScenarioRule(HostMainActivity::class.java)

    @Test
    fun hostShowsTryFieldAndSettingsButton() {
        onView(withId(R.id.tryField)).check(matches(isDisplayed()))
        onView(withId(R.id.openSettings)).check(matches(isDisplayed()))
    }
}
