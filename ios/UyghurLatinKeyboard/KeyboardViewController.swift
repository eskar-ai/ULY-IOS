import UIKit
import UyghurLatinKit

final class KeyboardViewController: UIInputViewController {
    private var engine: SuggestionEngine?
    private var engineFailed = false
    private var keyboardView: KeyboardView!
    private var heightConstraint: NSLayoutConstraint?
    private var shiftOn = false

    private let loadQueue = DispatchQueue(label: "com.esqer.uyghurlatin.lexicon-load", qos: .userInitiated)
    private let suggestQueue = DispatchQueue(label: "com.esqer.uyghurlatin.suggest", qos: .userInitiated)
    private var suggestWorkItem: DispatchWorkItem?
    private var suggestGeneration: UInt64 = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Opaque keyboard canvas — prevents iOS material blur washing out QuickType.
        view.isOpaque = true
        if let input = view as? UIInputView {
            input.allowsSelfSizing = true
        }

        keyboardView = KeyboardView(frame: .zero)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.delegate = self
        view.addSubview(keyboardView)

        let height = view.heightAnchor.constraint(equalToConstant: preferredHeight)
        // Must beat system keyboard sizing; `.defaultHigh` is often broken by UIInputView.
        height.priority = UILayoutPriority(999)
        heightConstraint = height

        NSLayoutConstraint.activate([
            height,
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        applyChrome()
        applyPreferredHeight()
        keyboardView.setNeedsInputModeSwitchKey(needsInputModeSwitchKey)
        keyboardView.showStatus(.loading)
        loadEngineAsync()
    }

    override func loadView() {
        // `.keyboard` style keeps the system rounded top corners while giving us
        // a proper opaque input surface for custom keys + QuickType.
        let input = UIInputView(frame: .zero, inputViewStyle: .keyboard)
        input.allowsSelfSizing = true
        input.isOpaque = true
        view = input
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardView.reloadPreferences(traits: traitCollection)
        applyChrome()
        applyPreferredHeight()
        keyboardView.setNeedsInputModeSwitchKey(needsInputModeSwitchKey)
        scheduleSuggest()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        applyPreferredHeight()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyChrome()
        keyboardView.applyTheme(traits: traitCollection)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if textDocumentProxy.isSecureTextEntry == true {
            keyboardView.isHidden = true
            suggestWorkItem?.cancel()
        } else {
            keyboardView.isHidden = false
            scheduleSuggest()
        }
    }

    private var preferredHeight: CGFloat {
        let compact = traitCollection.verticalSizeClass == .compact
        let regular = traitCollection.horizontalSizeClass == .regular
        let base: CGFloat
        if regular {
            base = compact ? 320 : 348
        } else {
            base = compact ? 248 : 298
        }
        return (base * KeyboardPreferences.height.multiplier).rounded()
    }

    private func applyPreferredHeight() {
        let h = preferredHeight
        guard let heightConstraint else { return }
        if abs(heightConstraint.constant - h) > 0.5 {
            heightConstraint.constant = h
            view.invalidateIntrinsicContentSize()
            view.setNeedsLayout()
        }
    }

    private func applyChrome() {
        let style = KeyboardPreferences.theme.resolvedStyle(for: traitCollection)
        let color = KeyboardPalette.palette(style: style).background
        view.isOpaque = true
        view.backgroundColor = color
        keyboardView?.backgroundColor = color
    }

    private func loadEngineAsync() {
        loadQueue.async { [weak self] in
            let loaded: SuggestionEngine?
            var failed = false
            do {
                let store = try LexiconStore(bundle: .main)
                loaded = SuggestionEngine(store: store)
            } catch {
                loaded = nil
                failed = true
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.engine = loaded
                self.engineFailed = failed
                if failed {
                    self.keyboardView.showStatus(.failed)
                }
                self.scheduleSuggest()
            }
        }
    }

    private func clippedBeforeInput() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        if before.count <= 64 { return before }
        return String(before.suffix(64))
    }

    private func context() -> (partial: String, previous: String?, beforePrevious: String?) {
        let before = clippedBeforeInput()
        var i = before.endIndex
        while i > before.startIndex {
            let prev = before.index(before: i)
            let ch = before[prev]
            guard let scalar = ch.unicodeScalars.first,
                  ULYNormalizer.isWordCharacter(scalar) else { break }
            i = prev
        }
        let partial = String(before[i...])

        func scanWord(endingAt end: String.Index) -> (word: String?, start: String.Index) {
            var j = end
            while j > before.startIndex {
                let prev = before.index(before: j)
                if !before[prev].isWhitespace { break }
                j = prev
            }
            var k = j
            while k > before.startIndex {
                let prev = before.index(before: k)
                let ch = before[prev]
                guard let scalar = ch.unicodeScalars.first,
                      ULYNormalizer.isWordCharacter(scalar) else { break }
                k = prev
            }
            let word = k < j ? ULYNormalizer.lookupKey(String(before[k..<j])) : nil
            return (word, k)
        }

        let prevScan = scanWord(endingAt: i)
        let previous = prevScan.word
        let beforePrevious = previous == nil ? nil : scanWord(endingAt: prevScan.start).word
        return (partial, previous, beforePrevious)
    }

    private func scheduleSuggest() {
        if textDocumentProxy.isSecureTextEntry == true {
            keyboardView.updateCandidates([], misspelled: false, canAddWord: false)
            return
        }
        if engine == nil {
            keyboardView.showStatus(engineFailed ? .failed : .loading)
            return
        }
        suggestWorkItem?.cancel()
        suggestGeneration &+= 1
        let gen = suggestGeneration
        let work = DispatchWorkItem { [weak self] in
            self?.runSuggest(generation: gen)
        }
        suggestWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016, execute: work)
    }

    private func runSuggest(generation: UInt64) {
        guard generation == suggestGeneration else { return }
        guard let engine else {
            keyboardView.showStatus(engineFailed ? .failed : .loading)
            return
        }
        let ctx = context()
        suggestQueue.async { [weak self] in
            let result = engine.suggest(
                partial: ctx.partial,
                previousWord: ctx.previous,
                beforePreviousWord: ctx.beforePrevious,
                limit: 8
            )
            let canAdd = !ctx.partial.isEmpty
                && ctx.partial.count >= 2
                && !engine.isKnown(ctx.partial)
            DispatchQueue.main.async {
                guard let self, generation == self.suggestGeneration else { return }
                self.keyboardView.updateCandidates(
                    result.candidates,
                    misspelled: result.isMisspelled,
                    canAddWord: canAdd || (result.isMisspelled && result.mode == .empty)
                )
            }
        }
    }

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
        if shiftOn && text.count == 1 {
            shiftOn = false
            keyboardView.setShift(false)
        }
        scheduleSuggest()
    }

    private func commitWordIfNeeded(thenInsert separator: String) {
        guard textDocumentProxy.isSecureTextEntry != true else {
            insert(separator)
            return
        }
        let ctx = context()
        if !ctx.partial.isEmpty {
            engine?.learnCommittedWord(
                ctx.partial,
                previous: ctx.previous,
                beforePrevious: ctx.beforePrevious
            )
        }
        insert(separator)
    }

    private func deleteBackward() {
        textDocumentProxy.deleteBackward()
        scheduleSuggest()
    }

    private func applyCandidate(_ word: String) {
        guard textDocumentProxy.isSecureTextEntry != true else { return }
        let ctx = context()
        if !ctx.partial.isEmpty {
            for _ in 0..<ctx.partial.count {
                textDocumentProxy.deleteBackward()
            }
        }
        textDocumentProxy.insertText(word + " ")
        engine?.learnSelection(word, previous: ctx.previous, beforePrevious: ctx.beforePrevious)
        scheduleSuggest()
    }

    private func addCurrentWord() {
        guard textDocumentProxy.isSecureTextEntry != true else { return }
        let ctx = context()
        let word = ULYNormalizer.lookupKey(ctx.partial)
        guard word.count >= 2 else { return }
        engine?.addToDictionary(word)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        scheduleSuggest()
    }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardView(_ view: KeyboardView, didTapKey key: KeyboardView.Key) {
        switch key {
        case .char(let s):
            guard !s.isEmpty else { return }
            insert(s)
        case .backspace:
            deleteBackward()
        case .space:
            commitWordIfNeeded(thenInsert: " ")
        case .returnKey:
            commitWordIfNeeded(thenInsert: "\n")
        case .shift:
            shiftOn.toggle()
            keyboardView.setShift(shiftOn)
        case .symbols:
            keyboardView.setLayer(.symbols)
        case .uly:
            keyboardView.setLayer(.uly)
        case .letters:
            keyboardView.setLayer(.letters)
        case .nextKeyboard:
            advanceToNextInputMode()
        }
    }

    func keyboardView(_ view: KeyboardView, didSelectCandidate word: String) {
        applyCandidate(word)
    }

    func keyboardViewDidTapAddWord(_ view: KeyboardView) {
        addCurrentWord()
    }
}
