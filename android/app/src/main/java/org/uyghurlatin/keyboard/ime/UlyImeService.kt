package org.uyghurlatin.keyboard.ime

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import org.uyghurlatin.engine.LexiconStore
import org.uyghurlatin.engine.PersonalDictionary
import org.uyghurlatin.engine.SuggestionEngine
import org.uyghurlatin.engine.UlyNormalizer

class UlyImeService : InputMethodService(), KeyboardLayoutView.Listener {
    private var keyboardView: KeyboardLayoutView? = null
    private var engine: SuggestionEngine? = null

    override fun onCreate() {
        super.onCreate()
        try {
            val store = LexiconStore.load(this)
            engine = SuggestionEngine(store, PersonalDictionary(this))
        } catch (_: Exception) {
            engine = null
        }
    }

    override fun onCreateInputView(): View {
        val view = KeyboardLayoutView(this, this)
        keyboardView = view
        refreshSuggestions()
        return view
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        refreshSuggestions()
    }

    override fun onUpdateSelection(
        oldSelStart: Int,
        oldSelEnd: Int,
        newSelStart: Int,
        newSelEnd: Int,
        candidatesStart: Int,
        candidatesEnd: Int,
    ) {
        super.onUpdateSelection(
            oldSelStart,
            oldSelEnd,
            newSelStart,
            newSelEnd,
            candidatesStart,
            candidatesEnd,
        )
        refreshSuggestions()
    }

    override fun onKey(text: String) {
        currentInputConnection?.commitText(text, 1)
        refreshSuggestions()
    }

    override fun onDelete() {
        val ic = currentInputConnection ?: return
        val selected = ic.getSelectedText(0)
        if (!selected.isNullOrEmpty()) {
            ic.commitText("", 1)
        } else {
            ic.deleteSurroundingText(1, 0)
        }
        refreshSuggestions()
    }

    override fun onSpace() {
        currentInputConnection?.commitText(" ", 1)
        refreshSuggestions()
    }

    override fun onReturn() {
        val ic = currentInputConnection ?: return
        val info = currentInputEditorInfo
        val action = info?.imeOptions?.and(EditorInfo.IME_MASK_ACTION) ?: EditorInfo.IME_ACTION_NONE
        if (action != EditorInfo.IME_ACTION_NONE && action != EditorInfo.IME_ACTION_UNSPECIFIED) {
            ic.performEditorAction(action)
        } else {
            ic.commitText("\n", 1)
        }
        refreshSuggestions()
    }

    override fun onShift() {
        // Layout handles visual shift state.
    }

    override fun onSpecialToggle() {
        // Layout handles special layer.
    }

    override fun onCandidate(word: String) {
        val ic = currentInputConnection ?: return
        val (partial, _) = contextWords()
        if (partial.isNotEmpty()) {
            ic.deleteSurroundingText(partial.length, 0)
        }
        ic.commitText("$word ", 1)
        engine?.learnSelection(word)
        refreshSuggestions()
    }

    private fun refreshSuggestions() {
        val eng = engine
        val view = keyboardView
        if (eng == null || view == null) {
            view?.updateCandidates(emptyList(), false)
            return
        }
        val (partial, previous) = contextWords()
        val result = eng.suggest(partial, previous, limit = 8)
        view.updateCandidates(result.candidates, result.isMisspelled)
    }

    private fun contextWords(): Pair<String, String?> {
        val ic = currentInputConnection ?: return "" to null
        val before = ic.getTextBeforeCursor(80, 0)?.toString() ?: ""
        var i = before.length
        while (i > 0 && UlyNormalizer.isWordChar(before[i - 1])) {
            i--
        }
        val partial = before.substring(i)

        var j = i
        while (j > 0 && before[j - 1].isWhitespace()) j--
        var k = j
        while (k > 0 && UlyNormalizer.isWordChar(before[k - 1])) k--
        val previous = if (k < j) UlyNormalizer.lookupKey(before.substring(k, j)) else null
        return partial to previous
    }
}
