package org.uyghurlatin.engine

import java.util.PriorityQueue

private class TrieNode {
    // HashMap: faster than TreeMap for insert/walk on hot IME path.
    val children = HashMap<Char, TrieNode>(4)
    var isWord = false
    var frequency = 0
    var word: String? = null
    /** Max frequency in this subtree — guides best-first completion. */
    var bestFrequency = 0
}

class PrefixTrie {
    private val root = TrieNode()

    fun insert(word: String, frequency: Int) {
        val key = UlyNormalizer.lookupKey(word)
        var node = root
        for (ch in key) {
            node = node.children.getOrPut(ch) { TrieNode() }
        }
        node.isWord = true
        node.frequency = maxOf(node.frequency, frequency)
        node.word = key
        // Refresh bestFrequency along the path (second pass up via walk stack).
        refreshBest(key, node.frequency)
    }

    fun contains(word: String): Boolean {
        val node = walk(UlyNormalizer.lookupKey(word))
        return node?.isWord == true
    }

    fun frequency(word: String): Int {
        val node = walk(UlyNormalizer.lookupKey(word))
        return if (node?.isWord == true) node.frequency else 0
    }

    /**
     * Top-[limit] completions by frequency using a bounded min-heap.
     * Avoids materializing then sorting large DFS lists on every keystroke.
     */
    fun completions(prefix: String, limit: Int = 8): List<Pair<String, Int>> {
        if (limit <= 0) return emptyList()
        val key = UlyNormalizer.lookupKey(prefix)
        if (key.isEmpty()) return emptyList()
        val start = walk(key) ?: return emptyList()

        val heap = PriorityQueue<Pair<String, Int>>(limit + 1, compareBy { it.second })
        fun consider(word: String, freq: Int) {
            if (heap.size < limit) {
                heap.add(word to freq)
            } else if (freq > heap.peek().second) {
                heap.poll()
                heap.add(word to freq)
            }
        }

        // Best-first: expand nodes with higher subtree bestFrequency first.
        val stack = ArrayDeque<TrieNode>()
        stack.add(start)
        var visited = 0
        val visitCap = maxOf(limit * 64, 256)
        while (stack.isNotEmpty() && visited < visitCap) {
            val node = stack.removeLast()
            visited++
            val w = node.word
            if (node.isWord && w != null) consider(w, node.frequency)
            // Push children low→high so high bestFrequency is popped last (DFS-ish priority).
            val kids = node.children.values.sortedBy { it.bestFrequency }
            for (child in kids) {
                if (heap.size >= limit && child.bestFrequency <= heap.peek().second) continue
                stack.add(child)
            }
        }

        return heap.sortedWith(compareByDescending<Pair<String, Int>> { it.second }.thenBy { it.first })
    }

    private fun refreshBest(key: String, leafFreq: Int) {
        var node = root
        node.bestFrequency = maxOf(node.bestFrequency, leafFreq)
        for (ch in key) {
            node = node.children[ch] ?: return
            node.bestFrequency = maxOf(node.bestFrequency, leafFreq)
        }
    }

    private fun walk(key: String): TrieNode? {
        var node = root
        for (ch in key) {
            node = node.children[ch] ?: return null
        }
        return node
    }
}
