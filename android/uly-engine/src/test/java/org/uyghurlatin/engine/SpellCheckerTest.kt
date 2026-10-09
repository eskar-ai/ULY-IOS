package org.uyghurlatin.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class SpellCheckerTest {
    private lateinit var trie: PrefixTrie
    private lateinit var spell: SpellChecker

    @Before
    fun setUp() {
        trie = PrefixTrie()
        listOf("uyghur" to 100, "uyghurche" to 50, "bügün" to 80, "aq" to 90).forEach { (w, f) ->
            trie.insert(w, f)
        }
        spell = SpellChecker(
            trie,
            listOf("uyghur", "uyghurche", "bügün", "aq"),
            mapOf("uygur" to "uyghur"),
        )
    }

    @Test
    fun isCorrect_knownWord() {
        assertTrue(spell.isCorrect("uyghur"))
        assertFalse(spell.isCorrect("uygur"))
    }

    @Test
    fun suggestions_preferCorrectionMap() {
        val hits = spell.suggestions("uygur", 3)
        assertTrue(hits.isNotEmpty())
        assertEquals("uyghur", hits.first())
    }

    @Test
    fun suggestions_exactKnownReturnsSelf() {
        assertEquals(listOf("bügün"), spell.suggestions("bügün", 3))
    }
}
