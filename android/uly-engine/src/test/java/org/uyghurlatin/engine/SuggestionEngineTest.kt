package org.uyghurlatin.engine

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SuggestionEngineTest {
    private fun tinyStore(): LexiconStore {
        val root = JSONObject()
        root.put(
            "meta",
            JSONObject()
                .put("version", "test")
                .put("script", "uly")
                .put("wordCount", 3)
                .put("correctionCount", 1)
                .put("bigramCount", 1)
                .put("sources", JSONArray().put("test")),
        )
        root.put(
            "words",
            JSONArray()
                .put(JSONArray().put("uyghur").put(100))
                .put(JSONArray().put("uyghurche").put(50))
                .put(JSONArray().put("bugun").put(80)),
        )
        root.put("corrections", JSONObject().put("uygur", "uyghur"))
        root.put(
            "bigrams",
            JSONArray().put(JSONArray().put("bugun").put("uyghur").put(9)),
        )
        return LexiconStore.fromJson(root)
    }

    @Test
    fun suggest_completesPrefix() {
        val engine = SuggestionEngine(tinyStore())
        val result = engine.suggest("uygh", null, 5)
        assertEquals(SuggestionMode.COMPLETION, result.mode)
        assertTrue(result.candidates.contains("uyghur"))
    }

    @Test
    fun suggest_nextWordFromBigram() {
        val engine = SuggestionEngine(tinyStore())
        val result = engine.suggest("", "bugun", 3)
        assertEquals(SuggestionMode.NEXT_WORD, result.mode)
        assertEquals("uyghur", result.candidates.first())
    }

    @Test
    fun suggest_correctionFromMap() {
        val engine = SuggestionEngine(tinyStore())
        val result = engine.suggest("uygur", null, 3)
        assertEquals(SuggestionMode.CORRECTION, result.mode)
        assertEquals("uyghur", result.candidates.first())
    }
}
