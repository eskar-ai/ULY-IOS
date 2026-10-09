package org.uyghurlatin.engine

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UlyNormalizerTest {
    @Test
    fun lookupKey_foldsCaseAndDiacriticAliases() {
        assertEquals("ëlëm", UlyNormalizer.lookupKey("ÉlÉm"))
        assertEquals("a'b", UlyNormalizer.lookupKey("A\u2019B"))
    }

    @Test
    fun isWordChar_acceptsUlyLetters() {
        assertTrue(UlyNormalizer.isWordChar('ë'))
        assertTrue(UlyNormalizer.isWordChar('\''))
        assertFalse(UlyNormalizer.isWordChar(' '))
        assertFalse(UlyNormalizer.isWordChar('.'))
    }
}
