package org.uyghurlatin.engine

enum class SuggestionMode {
    COMPLETION,
    NEXT_WORD,
    CORRECTION,
    EMPTY,
}

data class SuggestionResult(
    val candidates: List<String>,
    val isMisspelled: Boolean,
    val mode: SuggestionMode,
)

class SuggestionEngine(
    private val store: LexiconStore,
    private val personal: PersonalDictionary = PersonalDictionary(),
) {
    val meta: LexiconMeta get() = store.meta

    /** Tiny LRU-ish cache: same (partial|prev|limit) within a burst of key events. */
    private var cacheKey: String? = null
    private var cacheValue: SuggestionResult? = null

    fun suggest(partial: String, previousWord: String?, limit: Int = 3): SuggestionResult {
        val p = UlyNormalizer.lookupKey(partial)
        val prevKey = previousWord?.let { UlyNormalizer.lookupKey(it) }
        val key = "$p|${prevKey.orEmpty()}|$limit"
        cacheValue?.let { cached ->
            if (cacheKey == key) return cached
        }

        val result = suggestUncached(p, prevKey, limit)
        cacheKey = key
        cacheValue = result
        return result
    }

    fun invalidateCache() {
        cacheKey = null
        cacheValue = null
    }

    private fun suggestUncached(p: String, previousWord: String?, limit: Int): SuggestionResult {
        if (p.isEmpty()) {
            val next = store.predictor.nextWords(previousWord, limit)
            return SuggestionResult(
                candidates = next,
                isMisspelled = false,
                mode = if (next.isNotEmpty()) SuggestionMode.NEXT_WORD else SuggestionMode.EMPTY,
            )
        }

        // Completions first — never pay for spell-check while the trie still matches.
        val comps = (
            personal.rankedPrefix(p, limit) +
                store.trie.completions(p, limit * 3)
            ).sortedByDescending { it.second }

        val words = unique(comps.map { it.first }, limit)
        if (words.isNotEmpty()) {
            val exact = store.trie.contains(p) || personal.contains(p)
            return SuggestionResult(
                candidates = words,
                isMisspelled = !exact && p.length > 2,
                mode = SuggestionMode.COMPLETION,
            )
        }

        // No prefix hits: corrections (skipped for very short prefixes inside SpellChecker).
        if (p.length >= 3) {
            val corr = store.spellChecker.suggestions(p, limit)
            if (corr.isNotEmpty()) {
                return SuggestionResult(corr, isMisspelled = true, mode = SuggestionMode.CORRECTION)
            }
        }

        return SuggestionResult(
            candidates = emptyList(),
            isMisspelled = !store.trie.contains(p),
            mode = SuggestionMode.EMPTY,
        )
    }

    fun learnSelection(word: String) {
        personal.learn(word, 5)
        invalidateCache()
    }

    fun addToDictionary(word: String) {
        personal.add(word)
        invalidateCache()
    }

    fun clearPersonalDictionary() {
        personal.clear()
        invalidateCache()
    }

    fun isKnown(word: String): Boolean =
        store.trie.contains(word) || personal.contains(word)

    private fun unique(items: List<String>, limit: Int): List<String> {
        val seen = mutableSetOf<String>()
        val out = mutableListOf<String>()
        for (i in items) {
            val k = UlyNormalizer.lookupKey(i)
            if (!seen.add(k)) continue
            out.add(k)
            if (out.size >= limit) break
        }
        return out
    }
}
