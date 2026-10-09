package org.uyghurlatin.engine

class NGramPredictor(
    bigramTuples: List<Triple<String, String, Int>>,
    unigrams: List<Pair<String, Int>>,
) {
    private val bigrams: Map<String, List<Pair<String, Int>>>
    private val unigramsSorted: List<Pair<String, Int>>

    init {
        val map = mutableMapOf<String, MutableList<Pair<String, Int>>>()
        for ((a, b, c) in bigramTuples) {
            val key = UlyNormalizer.lookupKey(a)
            val next = UlyNormalizer.lookupKey(b)
            map.getOrPut(key) { mutableListOf() }.add(next to c)
        }
        bigrams = map.mapValues { (_, list) -> list.sortedByDescending { it.second } }
        unigramsSorted = unigrams.sortedByDescending { it.second }
    }

    fun nextWords(previous: String?, limit: Int = 6): List<String> {
        if (!previous.isNullOrEmpty()) {
            val list = bigrams[UlyNormalizer.lookupKey(previous)]
            if (!list.isNullOrEmpty()) return list.take(limit).map { it.first }
        }
        return unigramsSorted.take(limit).map { it.first }
    }
}
