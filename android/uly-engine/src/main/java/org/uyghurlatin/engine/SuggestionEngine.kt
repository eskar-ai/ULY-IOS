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
    private val morphology = MorphologyExpander(store.trie)

    val meta: LexiconMeta get() = store.meta

    private var cacheKey: String? = null
    private var cacheValue: SuggestionResult? = null

    fun suggest(
        partial: String,
        previousWord: String?,
        limit: Int = 3,
        sentenceStart: Boolean = false,
    ): SuggestionResult {
        val p = UlyNormalizer.lookupKey(partial)
        val prevKey = previousWord?.let { UlyNormalizer.lookupKey(it) }
        val key = "$p|${prevKey.orEmpty()}|$sentenceStart|$limit"
        cacheValue?.let { cached ->
            if (cacheKey == key && p.isNotEmpty()) return cached
        }

        val result = suggestUncached(p, prevKey, limit, sentenceStart)
        if (p.isNotEmpty()) {
            cacheKey = key
            cacheValue = result
        }
        return result
    }

    fun invalidateCache() {
        cacheKey = null
        cacheValue = null
    }

    private fun suggestUncached(
        p: String,
        previousWord: String?,
        limit: Int,
        sentenceStart: Boolean,
    ): SuggestionResult {
        if (p.isEmpty()) {
            val ranked = mutableListOf<Pair<String, Int>>()
            if (sentenceStart || previousWord.isNullOrEmpty()) {
                ranked += personal.rankedOpeners(limit * 2)
                ranked += personal.wordScores.entries
                    .sortedByDescending { it.value }
                    .take(limit)
                    .map { it.key to (it.value + 40_000) }
            } else {
                ranked += personal.nextWords(previousWord, limit)
            }
            val staticNext = store.predictor.nextWords(
                if (sentenceStart) null else previousWord,
                limit * 2,
            )
            staticNext.forEachIndexed { idx, w -> ranked += w to (10_000 - idx) }
            ranked.sortByDescending { it.second }
            val words = unique(ranked.map { it.first }, limit)
            return SuggestionResult(
                candidates = words,
                isMisspelled = false,
                mode = if (words.isNotEmpty()) SuggestionMode.NEXT_WORD else SuggestionMode.EMPTY,
            )
        }

        var comps = personal.rankedPrefix(p, limit) + store.trie.completions(p, limit * 3)
        if (comps.size < limit) {
            comps = comps + morphology.expansions(p, limit * 2)
        }
        comps = comps.sortedByDescending { it.second }

        val words = unique(comps.map { it.first }, limit)
        if (words.isNotEmpty()) {
            val exact = store.trie.contains(p) || personal.contains(p)
            return SuggestionResult(
                candidates = words,
                isMisspelled = !exact && p.length > 2,
                mode = SuggestionMode.COMPLETION,
            )
        }

        if (p.length >= 3) {
            val corr = store.spellChecker.suggestions(p, limit)
            if (corr.isNotEmpty()) {
                val ranked = mutableListOf<Pair<String, Int>>()
                corr.forEachIndexed { idx, c ->
                    ranked += c to (500_000 - idx * 10)
                    for ((m, score) in morphology.expansions(c, limit)) {
                        ranked += m to (score + 100_000 - idx * 10)
                    }
                }
                ranked.sortByDescending { it.second }
                val morphWords = unique(ranked.map { it.first }, limit)
                if (morphWords.isNotEmpty()) {
                    return SuggestionResult(morphWords, isMisspelled = true, mode = SuggestionMode.CORRECTION)
                }
            }
        }

        return SuggestionResult(
            candidates = emptyList(),
            isMisspelled = !store.trie.contains(p),
            mode = SuggestionMode.EMPTY,
        )
    }

    fun learnSelection(
        word: String,
        previous: String? = null,
        sentenceStart: Boolean = false,
    ) {
        personal.learn(word, 6)
        if (sentenceStart || previous.isNullOrEmpty()) {
            personal.learnOpener(word, 22)
        } else {
            personal.learnBigram(previous, word, 4)
        }
        invalidateCache()
    }

    fun learnCommittedWord(
        word: String,
        previous: String?,
        sentenceStart: Boolean = false,
    ) {
        val key = UlyNormalizer.lookupKey(word)
        if (key.length < 2) return
        val boost = when {
            personal.contains(key) -> 2
            store.trie.contains(key) -> 1
            else -> 12
        }
        personal.learn(key, boost)
        if (sentenceStart || previous.isNullOrEmpty()) {
            personal.learnOpener(key, if (sentenceStart) 24 else 14)
        } else {
            personal.learnBigram(previous, key, if (boost >= 12) 4 else 2)
        }
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
