package org.uyghurlatin.engine

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PersonalDictionaryTest {
    @Test
    fun learn_and_rankedPrefix_withoutContext() {
        val personal = PersonalDictionary(context = null)
        personal.learn("uyghurlar", 5)
        assertTrue(personal.contains("Uyghurlar"))
        val ranked = personal.rankedPrefix("uygh", 5)
        assertTrue(ranked.any { it.first == "uyghurlar" })
        personal.clear()
        assertFalse(personal.contains("uyghurlar"))
    }
}
