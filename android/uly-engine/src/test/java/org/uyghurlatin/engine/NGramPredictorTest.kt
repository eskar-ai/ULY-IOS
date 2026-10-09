package org.uyghurlatin.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NGramPredictorTest {
    @Test
    fun nextWords_usesBigramWhenPresent() {
        val predictor = NGramPredictor(
            bigramTuples = listOf(
                Triple("bügün", "uyghur", 9),
                Triple("bügün", "aq", 2),
            ),
            unigrams = listOf("aq" to 100, "uyghur" to 50),
        )
        val next = predictor.nextWords("bügün", 2)
        assertEquals("uyghur", next.first())
        assertEquals(2, next.size)
    }

    @Test
    fun nextWords_fallsBackToUnigrams() {
        val predictor = NGramPredictor(
            bigramTuples = emptyList(),
            unigrams = listOf("aq" to 100, "qara" to 80),
        )
        val next = predictor.nextWords(null, 2)
        assertEquals(listOf("aq", "qara"), next)
        assertTrue(predictor.nextWords("missing", 1).isNotEmpty())
    }
}
