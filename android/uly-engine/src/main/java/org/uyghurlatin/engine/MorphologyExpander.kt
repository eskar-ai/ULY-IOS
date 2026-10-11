package org.uyghurlatin.engine

class MorphologyExpander(private val trie: PrefixTrie) {
    fun expansions(partial: String, limit: Int): List<Pair<String, Int>> {
        if (limit <= 0) return emptyList()
        val key = UlyNormalizer.lookupKey(partial)
        if (key.length < MIN_STEM) return emptyList()

        val ranked = mutableListOf<Pair<String, Int>>()
        val seen = mutableSetOf<String>()

        fun consider(word: String, score: Int) {
            val w = UlyNormalizer.lookupKey(word)
            if (w == key) return
            if (!(w.startsWith(key) || isRelatedAlternate(key, w))) return
            if (!seen.add(w)) return
            ranked.add(w to score)
        }

        var stemEnd = key.length
        var stemsFound = 0
        while (stemEnd >= MIN_STEM && stemsFound < 4) {
            val stem = key.substring(0, stemEnd)
            if (trie.contains(stem)) {
                stemsFound++
                val stemFreq = maxOf(1, trie.frequency(stem))
                expand(stem, key.substring(stemEnd), stemFreq, ::consider)
            }
            stemEnd--
        }

        if (stemsFound == 0) {
            stemEnd = key.length - 1
            while (stemEnd >= MIN_STEM) {
                val stem = key.substring(0, stemEnd)
                if (trie.contains(stem)) {
                    val stemFreq = maxOf(1, trie.frequency(stem))
                    expand(stem, key.substring(stemEnd), stemFreq, ::consider)
                    break
                }
                stemEnd--
            }
        }

        return ranked.sortedWith(compareByDescending<Pair<String, Int>> { it.second }.thenBy { it.first.length })
            .take(limit)
    }

    private fun expand(
        stem: String,
        remainder: String,
        stemFreq: Int,
        consider: (String, Int) -> Unit,
    ) {
        for (suffix in SUFFIXES) {
            val form = stem + suffix
            if (remainder.isEmpty()) {
                consider(form, stemFreq / 4 - suffix.length * 10)
            } else if (suffix.startsWith(remainder)) {
                consider(form, stemFreq / 2 - (suffix.length - remainder.length) * 5)
            }
        }
        if (remainder.isNotEmpty()) {
            for (family in FAMILIES) {
                val matched = family.any {
                    it == remainder || it.startsWith(remainder) || remainder.startsWith(it)
                }
                if (!matched) continue
                for (alt in family) {
                    if (alt == remainder) continue
                    val boost = if (remainder in family) 200 else 0
                    consider(stem + alt, stemFreq / 3 - kotlin.math.abs(alt.length - remainder.length) * 8 + boost)
                }
            }
        }
    }

    private fun isRelatedAlternate(typed: String, candidate: String): Boolean {
        if (candidate.startsWith(typed)) return true
        var stemEnd = typed.length
        while (stemEnd >= MIN_STEM) {
            val stem = typed.substring(0, stemEnd)
            if (candidate.startsWith(stem) && trie.contains(stem)) {
                val typedRem = typed.substring(stemEnd)
                val candRem = candidate.substring(stem.length)
                for (family in FAMILIES) {
                    if (typedRem in family && candRem in family) return true
                }
            }
            stemEnd--
        }
        return false
    }

    companion object {
        private const val MIN_STEM = 3
        private val SUFFIXES = listOf(
            "turdigizmu", "turdingizmu", "turdingiz", "turdigiz", "turding",
            "turdum", "turduq", "turdi", "turdu", "tur",
            "digizmu", "dingizmu", "dingiz", "digiz", "gizmu", "izmu",
            "watimen", "watisen", "watisiz", "watidu", "watimiz", "watidilar",
            "uwatimen", "uwatidu", "iwatimen", "iwatidu",
            "ding", "dum", "duq", "di", "du",
            "musiler", "musiz", "misiz", "musen",
            "siler", "siz", "sen", "men", "miz",
            "imen", "isen", "isiz", "idu", "imiz", "idilar",
            "ayli", "eyli", "ay", "ey", "ingiz", "ing", "sun",
            "lar", "ler", "ning", "ni", "gha", "qa", "da", "de", "din", "tin",
            "mu", "chu", "ghu", "ken", "im",
        )
        private val FAMILIES = listOf(
            listOf("mu", "musiz", "misiz", "musen", "musiler"),
            listOf("siz", "sen", "men", "siler", "miz"),
            listOf("ding", "dingiz", "dingizmu", "digizmu", "digiz", "gizmu", "izmu"),
            listOf("di", "du", "dum", "duq", "ding", "dingiz"),
            listOf("turding", "turdingiz", "turdingizmu", "turdigizmu", "turdigiz", "turdi", "turdu", "turdum", "turduq"),
            listOf("watimen", "watisen", "watisiz", "watidu", "watimiz", "watidilar"),
            listOf("imen", "isen", "isiz", "idu", "imiz", "idilar"),
            listOf("lar", "ler", "ning", "ni", "gha", "qa", "da", "de", "din", "tin"),
            listOf("chu", "ghu", "ken", "mu"),
        )
    }
}
