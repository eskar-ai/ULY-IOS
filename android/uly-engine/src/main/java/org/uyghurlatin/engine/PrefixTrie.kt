package org.uyghurlatin.engine

private class TrieNode {
    val children = sortedMapOf<Char, TrieNode>()
    var isWord = false
    var frequency = 0
    var word: String? = null
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
    }

    fun contains(word: String): Boolean {
        val node = walk(UlyNormalizer.lookupKey(word))
        return node?.isWord == true
    }

    fun frequency(word: String): Int {
        val node = walk(UlyNormalizer.lookupKey(word))
        return if (node?.isWord == true) node.frequency else 0
    }

    fun completions(prefix: String, limit: Int = 8): List<Pair<String, Int>> {
        val key = UlyNormalizer.lookupKey(prefix)
        if (key.isEmpty()) return emptyList()
        val node = walk(key) ?: return emptyList()
        val results = mutableListOf<Pair<String, Int>>()
        collect(node, results, maxOf(limit * 4, 32))
        return results
            .sortedWith(compareByDescending<Pair<String, Int>> { it.second }.thenBy { it.first })
            .take(limit)
    }

    private fun walk(key: String): TrieNode? {
        var node = root
        for (ch in key) {
            node = node.children[ch] ?: return null
        }
        return node
    }

    private fun collect(node: TrieNode, results: MutableList<Pair<String, Int>>, limit: Int) {
        if (results.size >= limit) return
        val w = node.word
        if (node.isWord && w != null) results.add(w to node.frequency)
        for ((_, child) in node.children) {
            collect(child, results, limit)
            if (results.size >= limit) return
        }
    }
}
