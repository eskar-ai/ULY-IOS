package org.uyghurlatin.engine

class SpellChecker(
    private val trie: PrefixTrie,
    vocabulary: List<String>,
    private val corrections: Map<String, String>,
) {
    private val byLength: Map<Int, List<String>>

    init {
        val buckets = mutableMapOf<Int, MutableList<String>>()
        for (w in vocabulary) {
            buckets.getOrPut(w.length) { mutableListOf() }.add(w)
        }
        // Pre-sorted by frequency once at load — hot path must not re-sort.
        byLength = buckets.mapValues { (_, list) ->
            list.sortedByDescending { trie.frequency(it) }
        }
    }

    fun isCorrect(word: String): Boolean = trie.contains(word)

    fun suggestions(word: String, limit: Int = 6): List<String> {
        val key = UlyNormalizer.lookupKey(word)
        if (key.isEmpty()) return emptyList()
        if (trie.contains(key)) return listOf(key)

        // Short tokens: correction map only (edit-distance over 120k words is too slow for IME).
        if (key.length < 3) {
            val mapped = corrections[key] ?: return emptyList()
            return listOf(mapped)
        }

        val ranked = mutableListOf<Pair<String, Int>>()
        val seen = mutableSetOf<String>()

        corrections[key]?.let { mapped ->
            if (seen.add(mapped)) {
                ranked.add(mapped to (1_000_000 + trie.frequency(mapped)))
            }
        }
        // Fast path: mapped correction is usually enough for the bar.
        if (ranked.size >= limit) {
            return ranked.sortedByDescending { it.second }.take(limit).map { it.first }
        }

        val first = key[0]
        val cap = if (key.length <= 4) 600 else 1200
        var scanned = 0
        for (len in maxOf(1, key.length - 2)..(key.length + 2)) {
            val bucket = byLength[len] ?: continue
            for (cand in bucket) {
                if (scanned >= cap) break
                if (cand[0] != first && kotlin.math.abs(cand.length - key.length) > 1) {
                    // Cheap reject: different initial + length drift.
                    continue
                }
                scanned++
                if (cand in seen) continue
                val d = editDistance(key, cand, 2)
                if (d < 0 || d > 2) continue
                seen.add(cand)
                ranked.add(cand to (trie.frequency(cand) - d * 50_000))
                if (ranked.size >= limit * 4) break
            }
            if (scanned >= cap || ranked.size >= limit * 4) break
        }

        if (ranked.size < limit) {
            val folded = foldDiacritics(key)
            for (cand in byLength[key.length].orEmpty()) {
                if (cand in seen) continue
                if (foldDiacritics(cand) == folded) {
                    seen.add(cand)
                    ranked.add(cand to (trie.frequency(cand) + 10_000))
                    if (ranked.size >= limit) break
                }
            }
        }

        return ranked.sortedByDescending { it.second }.take(limit).map { it.first }
    }

    companion object {
        private fun foldDiacritics(s: String): String =
            s.replace("ö", "o").replace("ü", "u").replace("ë", "e").replace("é", "e")

        private fun editDistance(a: String, b: String, max: Int): Int {
            val n = a.length
            val m = b.length
            if (kotlin.math.abs(n - m) > max) return -1
            if (n == 0) return m
            if (m == 0) return n
            var prev = IntArray(m + 1) { it }
            var cur = IntArray(m + 1)
            for (i in 1..n) {
                cur[0] = i
                var rowMin = cur[0]
                for (j in 1..m) {
                    val cost = if (a[i - 1] == b[j - 1]) 0 else 1
                    cur[j] = minOf(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
                    rowMin = minOf(rowMin, cur[j])
                }
                if (rowMin > max) return -1
                val tmp = prev
                prev = cur
                cur = tmp
            }
            val d = prev[m]
            return if (d > max) -1 else d
        }
    }
}
