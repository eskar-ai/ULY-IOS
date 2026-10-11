package org.uyghurlatin.engine

import android.content.Context
import org.json.JSONObject

class PersonalDictionary(private val context: Context? = null) {
    private val lock = Any()
    private val words = mutableMapOf<String, Int>()

    init {
        load()
    }

    fun learn(word: String, boost: Int = 1) {
        val key = UlyNormalizer.lookupKey(word)
        if (key.isEmpty()) return
        synchronized(lock) {
            words[key] = (words[key] ?: 0) + boost
            persistLocked()
        }
    }

    fun add(word: String) = learn(word, 100)

    fun clear() {
        synchronized(lock) {
            words.clear()
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

    private fun load() {
        val prefs = context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE) ?: return
        val raw = prefs.getString(KEY, null) ?: return
        synchronized(lock) {
            try {
                val obj = JSONObject(raw)
                val keys = obj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    words[k] = obj.optInt(k, 0)
                }
            } catch (_: Exception) {
                words.clear()
            }
        }
    }

    /** Caller must hold [lock]. */
    private fun persistLocked() {
        val prefs = context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE) ?: return
        val obj = JSONObject()
        for ((k, v) in words) obj.put(k, v)
        prefs.edit().putString(KEY, obj.toString()).apply()
    }

    companion object {
        private const val PREFS = "uyghurlatin"
        private const val KEY = "personalWords"
    }
}
