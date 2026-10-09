package org.uyghurlatin.keyboard.ime

import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.view.View
import android.view.inputmethod.EditorInfo
import org.uyghurlatin.engine.LexiconStore
import org.uyghurlatin.engine.PersonalDictionary
import org.uyghurlatin.engine.SuggestionEngine
import org.uyghurlatin.engine.UlyNormalizer
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/**
 * IME best-practice notes:
 * - Lexicon load off the main thread (2.6MB JSON must not jank first frame).
 * - Key commit is synchronous; suggestion refresh is debounced.
 * - Password / private fields: no learning, no candidate bar content.
 */
class UlyImeService : InputMethodService(), KeyboardLayoutView.Listener {
    private var keyboardView: KeyboardLayoutView? = null
    @Volatile private var engine: SuggestionEngine? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private val loadExecutor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "uly-lexicon-load").apply { priority = Thread.NORM_PRIORITY - 1 }
    }
    private val suggestExecutor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "uly-suggest").apply { priority = Thread.NORM_PRIORITY - 1 }
    }
    private val suggestGeneration = AtomicInteger(0)
    private var suggestDebounce: Runnable? = null
    private var privateField = false

    override fun onCreate() {
        super.onCreate()
        val appCtx = applicationContext
        loadExecutor.execute {
            try {
                val store = LexiconStore.load(appCtx)
                val eng = SuggestionEngine(store, PersonalDictionary(appCtx))
                mainHandler.post {
                    engine = eng
                    scheduleSuggest()
                }
            } catch (_: Exception) {
                mainHandler.post { engine = null }
            }
        }
    }

    override fun onDestroy() {
        suggestDebounce?.let { mainHandler.removeCallbacks(it) }
        loadExecutor.shutdownNow()
        suggestExecutor.shutdownNow()
        super.onDestroy()
    }

    override fun onCreateInputView(): View {
        val view = KeyboardLayoutView(this, this)
        keyboardView = view
        scheduleSuggest()
        return view
    }

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        privateField = isPrivateEditor(attribute)
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        privateField = isPrivateEditor(info)
        if (privateField) {
            keyboardView?.updateCandidates(emptyList(), false)
        } else {
            scheduleSuggest()
        }
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
        scheduleSuggest()
    }

    override fun onKey(text: String) {
        currentInputConnection?.commitText(text, 1)
        scheduleSuggest()
    }

    override fun onDelete() {
        val ic = currentInputConnection ?: return
        val selected = ic.getSelectedText(0)
        if (!selected.isNullOrEmpty()) {
            ic.commitText("", 1)
        } else {
            ic.deleteSurroundingText(1, 0)
        }
        scheduleSuggest()
    }

    override fun onSpace() {
        currentInputConnection?.commitText(" ", 1)
        scheduleSuggest()
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
        scheduleSuggest()
    }

    override fun onShift() = Unit

    override fun onSpecialToggle() = Unit

    override fun onCandidate(word: String) {
        if (privateField) return
        val ic = currentInputConnection ?: return
        val (partial, _) = contextWords()
        ic.beginBatchEdit()
        try {
            if (partial.isNotEmpty()) {
                ic.deleteSurroundingText(partial.length, 0)
            }
            ic.commitText("$word ", 1)
        } finally {
            ic.endBatchEdit()
        }
        engine?.learnSelection(word)
        scheduleSuggest()
    }

    private fun scheduleSuggest() {
        suggestDebounce?.let { mainHandler.removeCallbacks(it) }
        val r = Runnable { runSuggestAsync() }
        suggestDebounce = r
        // ~1 frame: keeps key-to-glyph latency free of suggestion work.
        mainHandler.postDelayed(r, 16L)
    }

    private fun runSuggestAsync() {
        val view = keyboardView ?: return
        if (privateField) {
            view.updateCandidates(emptyList(), false)
            return
        }
        val eng = engine
        if (eng == null) {
            view.updateCandidates(emptyList(), false)
            return
        }
        val (partial, previous) = contextWords()
        val gen = suggestGeneration.incrementAndGet()
        suggestExecutor.execute {
            val result = eng.suggest(partial, previous, limit = 8)
            if (gen != suggestGeneration.get()) return@execute
            mainHandler.post {
                if (gen != suggestGeneration.get()) return@post
                keyboardView?.updateCandidates(result.candidates, result.isMisspelled)
            }
        }
    }

    private fun contextWords(): Pair<String, String?> {
        val ic = currentInputConnection ?: return "" to null
        val before = ic.getTextBeforeCursor(64, 0)?.toString() ?: ""
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

    private fun isPrivateEditor(info: EditorInfo?): Boolean {
        if (info == null) return false
        val variety = info.inputType and InputType.TYPE_MASK_VARIATION
        val klass = info.inputType and InputType.TYPE_MASK_CLASS
        if (klass == InputType.TYPE_CLASS_TEXT) {
            when (variety) {
                InputType.TYPE_TEXT_VARIATION_PASSWORD,
                InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD,
                InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD,
                -> return true
            }
        }
        if (klass == InputType.TYPE_CLASS_NUMBER &&
            variety == InputType.TYPE_NUMBER_VARIATION_PASSWORD
        ) {
            return true
        }
        return false
    }
}
