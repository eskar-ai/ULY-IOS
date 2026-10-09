package org.uyghurlatin.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PrefixTrieTest {
    @Test
    fun completions_rankByFrequency() {
        val trie = PrefixTrie()
        trie.insert("uyghur", 10)
        trie.insert("uyghurche", 5)
        trie.insert("uy", 1)
        val hits = trie.completions("uygh", 5)
        assertTrue(hits.isNotEmpty())
        assertEquals("uyghur", hits.first().first)
    }

    @Test
    fun contains_isCaseInsensitive() {
        val trie = PrefixTrie()
        trie.insert("Bugun", 3)
        assertTrue(trie.contains("bugun"))
        assertEquals(3, trie.frequency("BUGUN"))
    }
}
