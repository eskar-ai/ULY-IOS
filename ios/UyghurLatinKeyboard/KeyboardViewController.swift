import UIKit
import UyghurLatinKit

final class KeyboardViewController: UIInputViewController {
    private enum ShiftState { case off, on, locked }

    /// Only touched on the main thread; every call *into* it goes through `engineQueue`.
    private var engine: SuggestionEngine?
    private var engineFailed = false
    private var keyboardView: KeyboardView!
    private var heightConstraint: NSLayoutConstraint?
    private var inputCanvas: SelfSizingInputView?

    private var shiftState: ShiftState = .off
    /// Shift was turned on by auto-capitalization (not by the user), so it may be turned off again.
    private var shiftIsAuto = false
    /// Text before the cursor when the user dismissed auto-shift; suppresses re-arming there.
    private var autoShiftSuppressedAt: String?
    /// The space before the cursor was inserted by a candidate pick, not typed.
    private var pendingAutoSpace = false
    /// Time of the previous space press when nothing else happened since (double-space period).
    private var lastSpaceAt: CFTimeInterval = 0
    /// Top suggestion for the partial it was computed for (space autocorrect).
    private var lastSuggestion: (partial: String, first: String, isCorrection: Bool)?
    /// Last space-autocorrect, so an immediate backspace can undo it.
    private var lastAutocorrection: (original: String, replacement: String)?
    /// Word whose autocorrect the user just undid; not corrected again.
    private var rejectedAutocorrect: String?
    private var autocorrectEnabled = KeyboardPreferences.autocorrectEnabled
    private var lastKeyboardType: UIKeyboardType?

    /// Serial queue that owns all engine state (suggest, learning, persistence, reloads).
    private let engineQueue = DispatchQueue(label: "com.esqer.uyghurlatin.engine", qos: .userInitiated)
    private var suggestWorkItem: DispatchWorkItem?
    private var suggestGeneration: UInt64 = 0

    private static let spaceEatingPunctuation: Set<String> = [".", ",", "!", "?", ":", ";"]

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

        let h = preferredHeight
        let height = view.heightAnchor.constraint(equalToConstant: h)
        // 999, not required: a required constant fights the host's encapsulated height
        // constraint and Auto Layout then breaks an arbitrary constraint.
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
        let input = SelfSizingInputView(frame: .zero, inputViewStyle: .keyboard)
        input.allowsSelfSizing = true
        input.isOpaque = true
        input.preferredHeight = KeyboardPreferences.resolvedKeyboardHeight(
            traits: .current,
            landscape: Self.isLandscape(UIScreen.main.bounds.size)
        )
        inputCanvas = input
        view = input
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardView.reloadPreferences(traits: traitCollection)
        autocorrectEnabled = KeyboardPreferences.autocorrectEnabled
        withEngine { engine in
            engine.reloadStarterPreferences()
            engine.reloadPersonal()
        }
        applyChrome()
        heightScale = KeyboardPreferences.heightScale
        applyPreferredHeight()
        keyboardView.setNeedsInputModeSwitchKey(needsInputModeSwitchKey)
        updateInputTraits()
        scheduleSuggest()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardView.resetTransientState()
        withEngine { $0.flushPersonal() }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        withEngine { $0.flushPersonal() }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        applyPreferredHeight(layoutNow: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyChrome()
        keyboardView.applyTheme(traits: traitCollection)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateInputTraits()
        scheduleSuggest()
    }

    /// Return-key label and layout extras from the focused field's traits.
    private func updateInputTraits() {
        let proxy = textDocumentProxy
        let (titleKey, emphasized): (String, Bool) = {
            switch proxy.returnKeyType ?? .default {
            case .go: return ("return_go", true)
            case .google, .yahoo, .search: return ("return_search", true)
            case .send: return ("return_send", true)
            case .done: return ("return_done", true)
            case .join: return ("return_join", true)
            case .route: return ("return_route", true)
            case .emergencyCall: return ("return_emergency", true)
            case .next: return ("return_next", false)
            case .continue: return ("return_continue", false)
            default: return ("return_default", false)
            }
        }()
        let type = proxy.keyboardType ?? .default
        let kind: KeyboardView.FieldKind
        switch type {
        case .emailAddress: kind = .email
        case .URL, .webSearch: kind = .url
        default: kind = .text
        }
        keyboardView.setInputTraits(
            returnTitle: NSLocalizedString(titleKey, comment: "Return key"),
            emphasized: emphasized,
            fieldKind: kind
        )
        if type != lastKeyboardType {
            lastKeyboardType = type
            switch type {
            case .numberPad, .phonePad, .decimalPad, .numbersAndPunctuation, .asciiCapableNumberPad:
                keyboardView.setLayer(.symbols)
            default:
                if keyboardView.currentLayer == .symbols { keyboardView.setLayer(.letters) }
            }
        }
    }

    private var isSecure: Bool {
        textDocumentProxy.isSecureTextEntry == true
    }

    /// Screen size for the upcoming rotation, so the height is right before layout.
    private var transitionScreenSize: CGSize?

    private var preferredHeight: CGFloat {
        let screen = transitionScreenSize ?? view.window?.windowScene?.screen.bounds.size ?? UIScreen.main.bounds.size
        return KeyboardPreferences.resolvedKeyboardHeight(traits: traitCollection, landscape: Self.isLandscape(screen))
    }

    private static func isLandscape(_ size: CGSize) -> Bool {
        size.width > size.height
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let screen = view.window?.windowScene?.screen.bounds.size ?? UIScreen.main.bounds.size
        // The keyboard spans the screen width, so a width change here means rotation.
        let rotating = abs(size.width - screen.width) > 1
        transitionScreenSize = rotating ? CGSize(width: screen.height, height: screen.width) : nil
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.applyPreferredHeight()
        }, completion: { [weak self] _ in
            self?.transitionScreenSize = nil
            self?.applyPreferredHeight()
        })
    }

    /// Read from the Keychain only when the keyboard appears, never per layout pass.
    private var heightScale: CGFloat = KeyboardPreferences.heightScale
    private var appliedHeight: CGFloat = -1
    private var appliedScale: CGFloat = -1

    /// No-op unless height or scale changed. `layoutNow` must be false when called from a
    /// layout callback, otherwise forcing layout re-enters `viewWillLayoutSubviews` forever.
    private func applyPreferredHeight(layoutNow: Bool = true) {
        let h = preferredHeight
        let scale = heightScale
        guard abs(h - appliedHeight) > 0.5 || abs(scale - appliedScale) > 0.001 else { return }
        appliedHeight = h
        appliedScale = scale
        inputCanvas?.preferredHeight = h
        if let heightConstraint, abs(heightConstraint.constant - h) > 0.5 {
            heightConstraint.constant = h
        }
        keyboardView?.applyHeightScale(scale, traits: traitCollection)
        view.invalidateIntrinsicContentSize()
        view.setNeedsLayout()
        if layoutNow {
            view.layoutIfNeeded()
        }
    }

    private func applyChrome() {
        let style = KeyboardPreferences.theme.resolvedStyle(for: traitCollection)
        let color = KeyboardPalette.palette(style: style).background
        view.isOpaque = true
        view.backgroundColor = color
        keyboardView?.backgroundColor = color
    }

    // MARK: - Engine

    private func loadEngineAsync() {
        let queue = engineQueue
        queue.async { [weak self] in
            let loaded: SuggestionEngine?
            do {
                let store = try LexiconStore(bundle: .main)
                loaded = SuggestionEngine(
                    store: store,
                    personal: PersonalDictionary(flushQueue: queue)
                )
            } catch {
                loaded = nil
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.engine = loaded
                self.engineFailed = loaded == nil
                if loaded == nil {
                    self.keyboardView.showStatus(.failed)
                }
                self.scheduleSuggest()
            }
            if let loaded {
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
                    loaded.prewarm()
                }
            }
        }
    }

    private func withEngine(_ body: @escaping (SuggestionEngine) -> Void) {
        guard let engine else { return }
        engineQueue.async { body(engine) }
    }

    // MARK: - Context

    private func clippedBeforeInput() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        if before.count <= 64 { return before }
        return String(before.suffix(64))
    }

    private func context() -> (
        partial: String,
        previous: String?,
        beforePrevious: String?,
        sentenceStart: Bool
    ) {
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

        // Skip trailing whitespace to inspect the boundary before the current word.
        var boundary = i
        while boundary > before.startIndex {
            let prev = before.index(before: boundary)
            if !before[prev].isWhitespace { break }
            boundary = prev
        }
        let sentenceStart: Bool = {
            if boundary == before.startIndex { return true }
            let prev = before.index(before: boundary)
            return Self.isSentencePunctuation(before[prev])
        }()

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

        // After sentence punctuation, do not condition on the previous sentence's last word.
        if sentenceStart {
            return (partial, nil, nil, true)
        }

        let prevScan = scanWord(endingAt: i)
        let previous = prevScan.word
        let beforePrevious = previous == nil ? nil : scanWord(endingAt: prevScan.start).word
        return (partial, previous, beforePrevious, false)
    }

    private static func isSentencePunctuation(_ ch: Character) -> Bool {
        switch ch {
        case ".", "!", "?", "…", ":", ";", "。", "！", "？", "\n":
            return true
        default:
            return false
        }
    }

    private static func endsSentence(_ ch: Character) -> Bool {
        switch ch {
        case ".", "!", "?", "…", "。", "！", "？":
            return true
        default:
            return ch.isNewline
        }
    }

    // MARK: - Shift / casing

    /// Whether the host field's autocapitalization asks for a capital at the cursor.
    private func wantsAutoCapital(before: String) -> Bool {
        let type = textDocumentProxy.autocapitalizationType ?? .sentences
        switch type {
        case .none:
            return false
        case .allCharacters:
            return true
        case .words:
            return before.last.map { $0.isWhitespace } ?? true
        case .sentences:
            guard let last = before.last else { return true }
            guard last.isWhitespace else { return false }
            var idx = before.endIndex
            while idx > before.startIndex {
                let prev = before.index(before: idx)
                let ch = before[prev]
                if ch.isNewline { return true }
                if !ch.isWhitespace { return Self.endsSentence(ch) }
                idx = prev
            }
            return true
        @unknown default:
            return false
        }
    }

    private func updateAutoShift() {
        guard shiftState != .locked else { return }
        let before = clippedBeforeInput()
        if let suppressed = autoShiftSuppressedAt, suppressed != before {
            autoShiftSuppressedAt = nil
        }
        let want = wantsAutoCapital(before: before) && autoShiftSuppressedAt == nil
        if want, shiftState == .off {
            setShiftState(.on, auto: true)
        } else if !want, shiftState == .on, shiftIsAuto {
            setShiftState(.off, auto: false)
        }
    }

    private func setShiftState(_ state: ShiftState, auto: Bool) {
        shiftState = state
        shiftIsAuto = state == .on && auto
        keyboardView.setShift(state != .off, locked: state == .locked)
    }

    private func candidateStyle(partial: String) -> CasingPolicy.Style {
        if partial.isEmpty {
            switch shiftState {
            case .off: return .lower
            case .on: return .capitalized
            case .locked: return .upper
            }
        }
        return CasingPolicy.style(partial: partial, sentenceStart: false)
    }

    /// Apply the active shift state to typed key text (digraphs like `sh` become `Sh`).
    private func casedKeyText(_ text: String) -> String {
        guard text.contains(where: { $0.isLetter }) else { return text }
        switch shiftState {
        case .off: return text
        case .on: return CasingPolicy.apply(word: text.lowercased(), style: .capitalized)
        case .locked: return text.uppercased()
        }
    }

    // MARK: - Suggestions

    private func scheduleSuggest() {
        updateAutoShift()
        if isSecure {
            suggestWorkItem?.cancel()
            suggestGeneration &+= 1
            lastSuggestion = nil
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
        guard engine != nil else {
            keyboardView.showStatus(engineFailed ? .failed : .loading)
            return
        }
        let ctx = context()
        let style = candidateStyle(partial: ctx.partial)
        withEngine { [weak self] engine in
            let result = engine.suggest(
                partial: ctx.partial,
                previousWord: ctx.previous,
                beforePreviousWord: ctx.beforePrevious,
                sentenceStart: ctx.sentenceStart,
                limit: KeyboardView.candidateSlots
            )
            let canAdd = ctx.partial.count >= 2 && !engine.isKnown(ctx.partial)
            let shown = result.candidates.map { CasingPolicy.apply(word: $0, style: style) }
            DispatchQueue.main.async {
                guard let self, generation == self.suggestGeneration else { return }
                self.lastSuggestion = shown.first.map {
                    (ctx.partial, $0, result.isMisspelled && result.mode == .correction)
                }
                self.keyboardView.updateCandidates(
                    shown,
                    misspelled: result.isMisspelled,
                    canAddWord: canAdd || (result.isMisspelled && result.mode == .empty)
                )
            }
        }
    }

    // MARK: - Editing

    /// Any key other than space ends double-space / autocorrect-undo windows.
    private func resetTransientEditState() {
        lastSpaceAt = 0
        lastAutocorrection = nil
    }

    private func insert(_ raw: String) {
        resetTransientEditState()
        let text = casedKeyText(raw)
        if Self.spaceEatingPunctuation.contains(text),
           pendingAutoSpace,
           textDocumentProxy.documentContextBeforeInput?.hasSuffix(" ") == true {
            textDocumentProxy.deleteBackward()
        }
        pendingAutoSpace = false
        textDocumentProxy.insertText(text)
        if shiftState == .on, text.contains(where: { $0.isLetter }) {
            setShiftState(.off, auto: false)
        }
        scheduleSuggest()
    }

    private func learnCommitted(_ word: String, ctx: (partial: String, previous: String?, beforePrevious: String?, sentenceStart: Bool)) {
        guard !isSecure, !word.isEmpty else { return }
        withEngine { engine in
            engine.learnCommittedWord(
                word,
                previous: ctx.previous,
                beforePrevious: ctx.beforePrevious,
                sentenceStart: ctx.sentenceStart
            )
        }
    }

    private func commitWordIfNeeded(thenInsert separator: String) {
        let ctx = context()
        learnCommitted(ctx.partial, ctx: ctx)
        pendingAutoSpace = false
        textDocumentProxy.insertText(separator)
        scheduleSuggest()
    }

    private func handleReturn() {
        resetTransientEditState()
        commitWordIfNeeded(thenInsert: "\n")
    }

    private func handleSpace() {
        let now = CACurrentMediaTime()
        let previousSpace = lastSpaceAt
        lastAutocorrection = nil
        let before = textDocumentProxy.documentContextBeforeInput ?? ""

        // Double space after a word → ". " (and auto-shift arms for the next sentence).
        if !isSecure, now - previousSpace < 0.45, before.hasSuffix(" "),
           let prev = before.dropLast().last, prev.isLetter || prev.isNumber {
            lastSpaceAt = 0
            pendingAutoSpace = false
            textDocumentProxy.deleteBackward()
            textDocumentProxy.insertText(". ")
            scheduleSuggest()
            return
        }
        lastSpaceAt = now

        let ctx = context()
        if autocorrectEnabled, !isSecure, !ctx.partial.isEmpty,
           textDocumentProxy.autocorrectionType != .no,
           rejectedAutocorrect != ctx.partial,
           let s = lastSuggestion, s.isCorrection, s.partial == ctx.partial,
           ULYNormalizer.lookupKey(s.first) != ULYNormalizer.lookupKey(ctx.partial) {
            for _ in 0..<ctx.partial.count { textDocumentProxy.deleteBackward() }
            textDocumentProxy.insertText(s.first + " ")
            lastAutocorrection = (ctx.partial, s.first)
            pendingAutoSpace = false
            learnCommitted(s.first, ctx: ctx)
            scheduleSuggest()
            return
        }
        rejectedAutocorrect = nil
        commitWordIfNeeded(thenInsert: " ")
    }

    private func deleteBackward() {
        lastSpaceAt = 0
        pendingAutoSpace = false
        if let fix = lastAutocorrection,
           textDocumentProxy.documentContextBeforeInput?.hasSuffix(fix.replacement + " ") == true {
            lastAutocorrection = nil
            for _ in 0..<(fix.replacement.count + 1) { textDocumentProxy.deleteBackward() }
            textDocumentProxy.insertText(fix.original)
            rejectedAutocorrect = fix.original
            scheduleSuggest()
            return
        }
        lastAutocorrection = nil
        textDocumentProxy.deleteBackward()
        scheduleSuggest()
    }

    /// Delete the word (plus trailing spaces) or one punctuation run before the cursor.
    private func deleteWordBackward() {
        resetTransientEditState()
        pendingAutoSpace = false
        let before = clippedBeforeInput()
        guard !before.isEmpty else { return }
        var idx = before.endIndex
        var count = 0
        while idx > before.startIndex, before[before.index(before: idx)].isWhitespace {
            idx = before.index(before: idx)
            count += 1
        }
        func isWordChar(_ ch: Character) -> Bool {
            ch.unicodeScalars.first.map(ULYNormalizer.isWordCharacter) ?? false
        }
        if idx > before.startIndex, isWordChar(before[before.index(before: idx)]) {
            while idx > before.startIndex, isWordChar(before[before.index(before: idx)]) {
                idx = before.index(before: idx)
                count += 1
            }
        } else if idx > before.startIndex {
            count += 1
        }
        for _ in 0..<max(count, 1) { textDocumentProxy.deleteBackward() }
        scheduleSuggest()
    }

    private func applyCandidate(_ shown: String) {
        guard !isSecure else { return }
        resetTransientEditState()
        let ctx = context()
        let key = ULYNormalizer.lookupKey(shown)
        let text = CasingPolicy.apply(word: key, style: candidateStyle(partial: ctx.partial))
        for _ in 0..<ctx.partial.count {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(text + " ")
        pendingAutoSpace = true
        if shiftState == .on {
            setShiftState(.off, auto: false)
        }
        withEngine { engine in
            engine.learnSelection(
                key,
                previous: ctx.previous,
                beforePrevious: ctx.beforePrevious,
                sentenceStart: ctx.sentenceStart
            )
        }
        scheduleSuggest()
    }

    private func addCurrentWord() {
        guard !isSecure else { return }
        let word = ULYNormalizer.lookupKey(context().partial)
        guard word.count >= 2 else { return }
        withEngine { $0.addToDictionary(word) }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        scheduleSuggest()
    }

    private func toggleShift() {
        switch shiftState {
        case .off:
            setShiftState(.on, auto: false)
        case .on:
            if shiftIsAuto { autoShiftSuppressedAt = clippedBeforeInput() }
            setShiftState(.off, auto: false)
        case .locked:
            setShiftState(.off, auto: false)
        }
        scheduleSuggest()
    }

    private func toggleCapsLock() {
        setShiftState(shiftState == .locked ? .off : .locked, auto: false)
        scheduleSuggest()
    }
}

extension SelfSizingInputView: UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardView(_ view: KeyboardView, didTapKey key: KeyboardView.Key) {
        switch key {
        case .char(let s):
            guard !s.isEmpty else { return }
            insert(s)
        case .backspace:
            deleteBackward()
        case .deleteWord:
            deleteWordBackward()
        case .space:
            handleSpace()
        case .returnKey:
            handleReturn()
        case .shift:
            toggleShift()
        case .capsLock:
            toggleCapsLock()
        case .symbols:
            keyboardView.setLayer(.symbols)
        case .uly:
            keyboardView.setLayer(.uly)
        case .letters:
            keyboardView.setLayer(.letters)
        case .nextKeyboard:
            advanceToNextInputMode()
        case .dismiss:
            dismissKeyboard()
        }
    }

    func keyboardView(_ view: KeyboardView, didSelectCandidate word: String) {
        applyCandidate(word)
    }

    func keyboardViewDidTapAddWord(_ view: KeyboardView) {
        addCurrentWord()
    }
}
