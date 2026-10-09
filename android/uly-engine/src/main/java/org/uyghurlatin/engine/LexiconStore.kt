package org.uyghurlatin.engine

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.InputStream

data class LexiconMeta(
    val version: String,
    val script: String,
    val wordCount: Int,
    val correctionCount: Int,
    val bigramCount: Int,
    val sources: List<String>,
    val notes: String?,
)

class LexiconStore private constructor(
    val meta: LexiconMeta,
    val trie: PrefixTrie,
    val spellChecker: SpellChecker,
    val predictor: NGramPredictor,
    val vocabulary: List<String>,
) {
    companion object {
        fun load(context: Context, assetPath: String = "lexicon.json"): LexiconStore {
            context.assets.open(assetPath).use { return fromStream(it) }
        }

        fun fromStream(stream: InputStream): LexiconStore {
            val text = stream.bufferedReader(Charsets.UTF_8).readText()
            return fromJson(JSONObject(text))
        }

        fun fromJson(root: JSONObject): LexiconStore {
            val metaObj = root.getJSONObject("meta")
            val sourcesArr = metaObj.optJSONArray("sources") ?: JSONArray()
            val sources = buildList {
                for (i in 0 until sourcesArr.length()) add(sourcesArr.getString(i))
            }
            val meta = LexiconMeta(
                version = metaObj.optString("version", ""),
                script = metaObj.optString("script", "uly"),
                wordCount = metaObj.optInt("wordCount", 0),
                correctionCount = metaObj.optInt("correctionCount", 0),
                bigramCount = metaObj.optInt("bigramCount", 0),
                sources = sources,
                notes = if (metaObj.has("notes") && !metaObj.isNull("notes")) {
                    metaObj.getString("notes")
                } else {
                    null
                },
            )

            val trie = PrefixTrie()
            val freqs = mutableMapOf<String, Int>()
            val vocab = mutableListOf<String>()
            val words = root.getJSONArray("words")
            for (i in 0 until words.length()) {
                val pair = words.getJSONArray(i)
                val w = pair.getString(0)
                val f = pair.getInt(1)
                val key = UlyNormalizer.lookupKey(w)
                freqs[key] = f
                vocab.add(key)
                trie.insert(key, f)
            }

            val correctionsMap = mutableMapOf<String, String>()
            val corr = root.optJSONObject("corrections")
            if (corr != null) {
                val keys = corr.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    correctionsMap[UlyNormalizer.lookupKey(k)] = UlyNormalizer.lookupKey(corr.getString(k))
                }
            }

            val bigrams = mutableListOf<Triple<String, String, Int>>()
            val bigArr = root.optJSONArray("bigrams") ?: JSONArray()
            for (i in 0 until bigArr.length()) {
                val t = bigArr.getJSONArray(i)
                bigrams.add(Triple(t.getString(0), t.getString(1), t.getInt(2)))
            }

            val spell = SpellChecker(trie, vocab, correctionsMap)
            val predictor = NGramPredictor(bigrams, freqs.toList())
            return LexiconStore(meta, trie, spell, predictor, vocab)
        }
    }
}
