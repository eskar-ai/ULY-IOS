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

    @Test
    fun learnBigram_and_opener_rank_nextWords() {
        val personal = PersonalDictionary(context = null)
        personal.learnBigram("salam", "yaxshimusiz", 5)
        personal.learnOpener("essalamu'eleykum", 20)
        val next = personal.nextWords("salam", 5)
        assertTrue(next.any { it.first == "yaxshimusiz" })
        val openers = personal.rankedOpeners(5)
        assertTrue(openers.any { it.first.contains("essalam") || it.first.contains("eleykum") })
        personal.clear()
    }
}
