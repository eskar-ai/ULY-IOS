package org.uyghurlatin.engine

import android.content.Context
import org.json.JSONObject

class PersonalDictionary(private val context: Context? = null) {
    private val lock = Any()
    private val words = mutableMapOf<String, Int>()
    private val bigrams = mutableMapOf<String, Int>()
    private val openers = mutableMapOf<String, Int>()

    init {
        load()
    }

    fun learn(word: String, boost: Int = 1) {
        val key = UlyNormalizer.lookupKey(word)
        if (key.isEmpty()) return
        synchronized(lock) {
            softDecayLocked()
            words[key] = (words[key] ?: 0) + boost
            persistLocked()
        }
    }

    fun add(word: String) = learn(word, 100)

    fun learnBigram(previous: String, word: String, boost: Int = 1) {
        val a = UlyNormalizer.lookupKey(previous)
        val b = UlyNormalizer.lookupKey(word)
        if (a.isEmpty() || b.isEmpty()) return
        val key = "$a$SEP$b"
        synchronized(lock) {
            bigrams[key] = (bigrams[key] ?: 0) + boost
            persistLocked()
        }
    }

    fun learnOpener(word: String, boost: Int = 18) {
        val key = UlyNormalizer.lookupKey(word)
        if (key.length < 2) return
        synchronized(lock) {
            openers[key] = (openers[key] ?: 0) + boost
            words[key] = (words[key] ?: 0) + maxOf(1, boost / 4)
            persistLocked()
        }
    }

    fun rankedOpeners(limit: Int): List<Pair<String, Int>> {
        if (limit <= 0) return emptyList()
        return synchronized(lock) {
            openers.entries
                .map { it.key to (it.value + 120_000) }
                .sortedByDescending { it.second }
                .take(limit)
        }
    }

    fun nextWords(after: String?, limit: Int): List<Pair<String, Int>> {
        if (after.isNullOrEmpty() || limit <= 0) return emptyList()
        val prev = UlyNormalizer.lookupKey(after)
        val needle = "$prev$SEP"
        return synchronized(lock) {
            bigrams.entries
                .mapNotNull { (key, count) ->
                    if (!key.startsWith(needle)) return@mapNotNull null
                    val next = key.removePrefix(needle)
                    if (next.isEmpty()) null else next to (count + 50_000)
                }
                .sortedByDescending { it.second }
                .take(limit)
        }
    }

    fun clear() {
        synchronized(lock) {
            words.clear()
            bigrams.clear()
            openers.clear()
            persistLocked()
        }
    }

    fun contains(word: String): Boolean {
        val key = UlyNormalizer.lookupKey(word)
        return synchronized(lock) { key in words }
    }

    fun rankedPrefix(prefix: String, limit: Int): List<Pair<String, Int>> {
        val p = UlyNormalizer.lookupKey(prefix)
        if (p.isEmpty()) return emptyList()
        return synchronized(lock) {
            words.entries
                .filter { it.key.startsWith(p) }
                .map { it.key to (it.value + 100_000) }
                .sortedByDescending { it.second }
                .take(limit)
        }
    }

    val wordScores: Map<String, Int>
        get() = synchronized(lock) { words.toMap() }

    private fun softDecayLocked() {
        if (words.size <= 400) return
        val it = words.entries.iterator()
        while (it.hasNext()) {
            val e = it.next()
            if (e.value in 1 until 20) {
                val next = e.value - 1
                if (next <= 0) it.remove() else e.setValue(next)
            }
        }
    }

    private fun load() {
        val prefs = context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE) ?: return
        synchronized(lock) {
            words.clear()
            bigrams.clear()
            openers.clear()
            words.putAll(readMap(prefs.getString(KEY_WORDS, null)))
            bigrams.putAll(readMap(prefs.getString(KEY_BIGRAMS, null)))
            openers.putAll(readMap(prefs.getString(KEY_OPENERS, null)))
        }
    }

    private fun persistLocked() {
        val prefs = context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE) ?: return
        prefs.edit()
            .putString(KEY_WORDS, toJson(words))
            .putString(KEY_BIGRAMS, toJson(bigrams))
            .putString(KEY_OPENERS, toJson(openers))
            .apply()
    }

    private fun readMap(raw: String?): Map<String, Int> {
        if (raw.isNullOrEmpty()) return emptyMap()
        return try {
            val obj = JSONObject(raw)
            val out = mutableMapOf<String, Int>()
            val keys = obj.keys()
            while (keys.hasNext()) {
                val k = keys.next()
                out[k] = obj.optInt(k, 0)
            }
            out
        } catch (_: Exception) {
            emptyMap()
        }
    }

    private fun toJson(map: Map<String, Int>): String {
        val obj = JSONObject()
        for ((k, v) in map) obj.put(k, v)
        return obj.toString()
    }

    companion object {
        private const val PREFS = "uyghurlatin"
        private const val KEY_WORDS = "personalWords"
        private const val KEY_BIGRAMS = "personalBigrams"
        private const val KEY_OPENERS = "personalOpeners"
        private const val SEP = "\u001f"
    }
}
