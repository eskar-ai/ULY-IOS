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

    fun suggest(partial: String, previousWord: String?, limit: Int = 3): SuggestionResult {
        val p = UlyNormalizer.lookupKey(partial)
        if (p.isEmpty()) {
            val next = store.predictor.nextWords(previousWord, limit)
            return SuggestionResult(
                candidates = next,
                isMisspelled = false,
                mode = if (next.isNotEmpty()) SuggestionMode.NEXT_WORD else SuggestionMode.EMPTY,
            )
        }

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

        val corr = store.spellChecker.suggestions(p, limit)
        if (corr.isNotEmpty()) {
            return SuggestionResult(corr, isMisspelled = true, mode = SuggestionMode.CORRECTION)
        }

        return SuggestionResult(
            candidates = emptyList(),
            isMisspelled = !store.trie.contains(p),
            mode = SuggestionMode.EMPTY,
        )
    }

    fun learnSelection(word: String) = personal.learn(word, 5)

    fun addToDictionary(word: String) = personal.add(word)

    fun clearPersonalDictionary() = personal.clear()

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
