package org.uyghurlatin.engine

object UlyNormalizer {
    fun normalize(text: String): String =
        text
            .replace("É", "Ë")
            .replace("é", "ë")
            .replace("ʼ", "'")
            .replace("\u2019", "'")

    fun lookupKey(text: String): String = normalize(text).lowercase()

    fun isWordChar(ch: Char): Boolean {
        if (ch == '\'' || ch == '\u2019' || ch == 'ʼ') return true
        return ch in 'A'..'Z' ||
            ch in 'a'..'z' ||
            ch == 'Ö' || ch == 'Ü' || ch == 'Ë' ||
            ch == 'ö' || ch == 'ü' || ch == 'ë' ||
            ch == 'É' || ch == 'é'
    }
}
