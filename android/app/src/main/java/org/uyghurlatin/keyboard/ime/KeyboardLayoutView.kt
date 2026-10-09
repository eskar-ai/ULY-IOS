package org.uyghurlatin.keyboard.ime

import android.content.Context
import android.graphics.Typeface
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import org.uyghurlatin.keyboard.R

class KeyboardLayoutView(
    context: Context,
    private val listener: Listener,
) : LinearLayout(context) {

    interface Listener {
        fun onKey(text: String)
        fun onDelete()
        fun onSpace()
        fun onReturn()
        fun onShift()
        fun onCandidate(word: String)
        fun onSpecialToggle()
    }

    private val candidatesRow: LinearLayout
    private val rows: List<LinearLayout>
    private var shiftOn = false
    private var specialOn = false

    private val alphaRows = listOf(
        listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p"),
        listOf("a", "s", "d", "f", "g", "h", "j", "k", "l"),
        listOf("⇧", "z", "x", "c", "v", "b", "n", "m", "⌫"),
        listOf("ëöü", ",", "space", ".", "⏎"),
    )

    private val specialRows = listOf(
        listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0"),
        listOf("ë", "ö", "ü", "ch", "sh", "zh", "gh", "ng", "'"),
        listOf("ABC", "-", "_", "!", "?", "@", "#", "⌫"),
        listOf("ëöü", ",", "space", ".", "⏎"),
    )

    init {
        LayoutInflater.from(context).inflate(R.layout.keyboard_view, this, true)
        candidatesRow = findViewById(R.id.candidatesRow)
        rows = listOf(
            findViewById(R.id.row1),
            findViewById(R.id.row2),
            findViewById(R.id.row3),
            findViewById(R.id.row4),
        )
        rebuildKeys()
    }

    fun updateCandidates(words: List<String>, misspelled: Boolean) {
        candidatesRow.removeAllViews()
        if (words.isEmpty()) {
            val hint = TextView(context).apply {
                text = if (misspelled) "…" else ""
                setTextColor(context.getColor(R.color.uly_misspelled))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setPadding(dp(8), 0, dp(8), 0)
            }
            candidatesRow.addView(hint)
            return
        }
        words.take(8).forEachIndexed { index, word ->
            val tv = TextView(context).apply {
                text = word
                setTextColor(
                    context.getColor(
                        if (misspelled && index == 0) R.color.uly_misspelled else R.color.uly_text,
                    ),
                )
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                typeface = Typeface.DEFAULT
                setPadding(dp(12), dp(6), dp(12), dp(6))
                setOnClickListener { listener.onCandidate(word) }
            }
            candidatesRow.addView(tv)
            if (index < words.lastIndex) {
                candidatesRow.addView(
                    View(context).apply {
                        layoutParams = LayoutParams(dp(1), dp(18)).apply {
                            gravity = Gravity.CENTER_VERTICAL
                        }
                        setBackgroundColor(0x33000000)
                    },
                )
            }
        }
    }

    fun setShift(on: Boolean) {
        shiftOn = on
        rebuildKeys()
    }

    private fun rebuildKeys() {
        val source = if (specialOn) specialRows else alphaRows
        source.forEachIndexed { rowIndex, labels ->
            val row = rows[rowIndex]
            row.removeAllViews()
            labels.forEach { label ->
                row.addView(makeKey(label, rowIndex))
            }
        }
    }

    private fun makeKey(label: String, rowIndex: Int): Button {
        val display = when {
            label == "⇧" -> if (shiftOn) "⇪" else "⇧"
            label.length == 1 && !specialOn && shiftOn -> label.uppercase()
            else -> label
        }
        val special = label in setOf("⇧", "⌫", "⏎", "ëöü", "ABC", "space", ",", ".")
        val weight = when (label) {
            "space" -> 4f
            "⇧", "⌫", "⏎", "ëöü", "ABC" -> 1.4f
            else -> 1f
        }
        return Button(context).apply {
            text = when (label) {
                "space" -> context.getString(R.string.key_space)
                "⏎" -> context.getString(R.string.key_return)
                else -> display
            }
            isAllCaps = false
            setTextSize(TypedValue.COMPLEX_UNIT_SP, if (label.length > 2) 12f else 18f)
            setTextColor(context.getColor(R.color.uly_text))
            background = context.getDrawable(
                if (special) R.drawable.key_bg_special else R.drawable.key_bg,
            )
            elevation = 1f
            layoutParams = LayoutParams(0, LayoutParams.MATCH_PARENT, weight).apply {
                marginStart = dp(2)
                marginEnd = dp(2)
            }
            setOnClickListener {
                when (label) {
                    "⇧" -> {
                        shiftOn = !shiftOn
                        listener.onShift()
                        rebuildKeys()
                    }
                    "⌫" -> listener.onDelete()
                    "space" -> listener.onSpace()
                    "⏎" -> listener.onReturn()
                    "ëöü" -> {
                        specialOn = !specialOn
                        listener.onSpecialToggle()
                        rebuildKeys()
                    }
                    "ABC" -> {
                        specialOn = false
                        rebuildKeys()
                    }
                    else -> {
                        val out = if (!specialOn && shiftOn && label.length == 1) {
                            label.uppercase()
                        } else {
                            label
                        }
                        listener.onKey(out)
                        if (shiftOn && label.length == 1) {
                            shiftOn = false
                            rebuildKeys()
                        }
                    }
                }
            }
            if (label in listOf("e", "o", "u", "c", "s", "z", "g", "n") && !specialOn) {
                setOnLongClickListener {
                    val alt = when (label) {
                        "e" -> "ë"
                        "o" -> "ö"
                        "u" -> "ü"
                        "c" -> "ch"
                        "s" -> "sh"
                        "z" -> "zh"
                        "g" -> "gh"
                        "n" -> "ng"
                        else -> label
                    }
                    val out = if (shiftOn && alt.length == 1) alt.uppercase() else alt
                    listener.onKey(out)
                    true
                }
            }
        }
    }

    private fun dp(v: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            v.toFloat(),
            resources.displayMetrics,
        ).toInt()
}
