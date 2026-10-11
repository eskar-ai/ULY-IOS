import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, didTapKey key: KeyboardView.Key)
    func keyboardView(_ view: KeyboardView, didSelectCandidate word: String)
    func keyboardViewDidTapAddWord(_ view: KeyboardView)
}

final class KeyboardView: UIView {
    enum Layer { case letters, symbols, uly }
    enum Key: Equatable {
        case char(String)
        case backspace, deleteWord, space, returnKey, shift, capsLock, symbols, uly, letters, nextKeyboard, dismiss
    }

    /// QuickType columns; the engine is asked for exactly this many candidates.
    static let candidateSlots = 3

    enum Status {
        case none
        case loading
        case failed
    }

    /// Extra keys beside space for the host field's `keyboardType`.
    enum FieldKind { case text, email, url }

    weak var delegate: KeyboardViewDelegate?

    /// Solid fill under the system rounded top so backdrop blur cannot show through.
    private let chromeFill = UIView()
    private let candidateBar = UIView()
    private let candidatesStack = UIStackView()
    private var candidateButtons: [UIButton] = []
    /// Word per candidate column; `addSlot` marks the "+ Add" column, "" an empty column.
    private var slotWords = ["", "", ""]
    private static let addSlot = "\u{0}add"
    private let sep1 = UIView()
    private let sep2 = UIView()
    private let statusLabel = UILabel()
    private let divider = UIView()
    private let rowsStack = UIStackView()
    private var keyButtons: [KeyButton] = []

    private var shiftOn = false
    private var capsLocked = false
    private var layerMode: Layer = .letters
    private var fieldKind: FieldKind = .text
    private var returnTitle = NSLocalizedString("return_default", comment: "Return key")
    private var returnEmphasized = false
    private var palette = KeyboardPalette.palette(style: .light)
    private var preference: KeyboardThemePreference = .system
    private var lastCandidates: [String] = []
    private var lastMisspelled = false
    private var canAddWord = false
    private var showGlobe = true
    private var status: Status = .none
    private var heightScale: CGFloat = KeyboardPreferences.heightScale
    private var candidateHeightConstraint: NSLayoutConstraint?
    private var chromeHeightConstraint: NSLayoutConstraint?
    private var rowsTopConstraint: NSLayoutConstraint?
    private var rowsBottomConstraint: NSLayoutConstraint?
    private var rowsLeadingConstraint: NSLayoutConstraint?
    private var rowsTrailingConstraint: NSLayoutConstraint?

    // Feedback (cached; reading Keychain per key press is too slow).
    private var soundEnabled = KeyboardPreferences.soundEnabled
    private var hapticsEnabled = KeyboardPreferences.hapticsEnabled
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    // Transient touch state.
    private var keyPreview: UIView?
    private var popup: UIView?
    private var popupLabels: [UILabel] = []
    private var popupOptions: [String] = []
    private var popupSelection = 0
    private var deleteTimer: Timer?
    private var deleteStartedAt: CFTimeInterval = 0
    private var lastShiftTapAt: CFTimeInterval = 0

    private var isRegularWidth: Bool { traitCollection.horizontalSizeClass == .regular }

    override init(frame: CGRect) {
        super.init(frame: frame)
        preference = KeyboardPreferences.theme
        heightScale = KeyboardPreferences.heightScale
        setup()
        applyTheme(traits: traitCollection)
        rebuildKeys()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let sizeChanged = previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
        let fontChanged = previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory
        if preference == .system || sizeChanged {
            applyTheme(traits: traitCollection)
            applyHeightMetrics(traits: traitCollection)
            rebuildKeys()
        } else if fontChanged {
            applyCandidatePresentation()
        }
    }

    func reloadPreferences(traits: UITraitCollection) {
        preference = KeyboardPreferences.theme
        heightScale = KeyboardPreferences.heightScale
        soundEnabled = KeyboardPreferences.soundEnabled
        hapticsEnabled = KeyboardPreferences.hapticsEnabled
        applyTheme(traits: traits)
        applyHeightMetrics(traits: traits)
        rebuildKeys()
    }

    /// Scale chrome metrics; key rows fill remaining height equally so resize is obvious.
    func applyHeightScale(_ scale: CGFloat, traits: UITraitCollection) {
        let clamped = KeyboardPreferences.clampScale(scale)
        guard abs(clamped - heightScale) > 0.001 else { return }
        heightScale = clamped
        applyHeightMetrics(traits: traits)
        // Rebuild so fonts / key spacing pick up the new scale.
        rebuildKeys()
    }

    private func applyHeightMetrics(traits: UITraitCollection) {
        let s = heightScale
        chromeHeightConstraint?.constant = (8 * min(max(s, 0.85), 1.15)).rounded()
        candidateHeightConstraint?.constant = (36 * min(max(s, 0.9), 1.12)).rounded()
        rowsTopConstraint?.constant = (8 * min(max(s, 0.85), 1.2)).rounded()
        rowsBottomConstraint?.constant = (-(5 * min(max(s, 0.85), 1.2))).rounded()
        rowsStack.spacing = (7 * min(max(s, 0.85), 1.25)).rounded()
        let inset: CGFloat = traits.horizontalSizeClass == .regular ? 6 : 3
        rowsLeadingConstraint?.constant = inset
        rowsTrailingConstraint?.constant = -inset
    }

    func setShift(_ on: Bool, locked: Bool = false) {
        guard shiftOn != on || capsLocked != locked else { return }
        shiftOn = on
        capsLocked = locked
        refreshKeyFaces()
    }

    func setLayer(_ layer: Layer) {
        guard layerMode != layer else { return }
        layerMode = layer
        rebuildKeys()
    }

    var currentLayer: Layer { layerMode }

    func setNeedsInputModeSwitchKey(_ needs: Bool) {
        guard showGlobe != needs else { return }
        showGlobe = needs
        rebuildKeys()
    }

    /// Return-key label/emphasis and extra keys from the host field's traits.
    func setInputTraits(returnTitle: String, emphasized: Bool, fieldKind: FieldKind) {
        let kindChanged = self.fieldKind != fieldKind
        self.returnTitle = returnTitle
        self.returnEmphasized = emphasized
        self.fieldKind = fieldKind
        if kindChanged {
            rebuildKeys()
        } else {
            refreshKeyFaces()
        }
    }

    /// Stop key repeat / popups (keyboard hidden or touches lost).
    func resetTransientState() {
        endDeleteRepeat()
        hideKeyPreview()
        hidePopup()
    }

    func applyTheme(traits: UITraitCollection) {
        let style = preference.resolvedStyle(for: traits)
        palette = KeyboardPalette.palette(style: style)

        // Fully opaque stack — translucent views let the iOS keyboard material
        // frost the QuickType row (exactly the blur seen in screenshots).
        isOpaque = true
        backgroundColor = palette.background
        chromeFill.isOpaque = true
        chromeFill.backgroundColor = palette.background
        candidateBar.isOpaque = true
        candidateBar.backgroundColor = palette.candidateBar
        candidatesStack.backgroundColor = palette.candidateBar
        divider.backgroundColor = palette.separator
        sep1.backgroundColor = palette.separator
        sep2.backgroundColor = palette.separator
        statusLabel.textColor = palette.candidateSecondary
        statusLabel.backgroundColor = palette.candidateBar
        applyCandidatePresentation()
    }

    func showStatus(_ status: Status) {
        self.status = status
        applyCandidatePresentation()
    }

    func updateCandidates(_ words: [String], misspelled: Bool, canAddWord: Bool = false) {
        status = .none
        lastCandidates = words
        lastMisspelled = misspelled
        self.canAddWord = canAddWord
        applyCandidatePresentation()
    }

    // MARK: - Candidate bar (3 reused buttons)

    private func candidateFont(emphasized: Bool, add: Bool) -> UIFont {
        let base = (add ? 15 : 17) * min(max(heightScale, 0.9), 1.15)
        let font = UIFont.systemFont(ofSize: base, weight: add || emphasized ? .semibold : .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font, maximumPointSize: base * 1.35, compatibleWith: traitCollection)
    }

    private func applyCandidatePresentation() {
        switch status {
        case .loading:
            statusLabel.text = NSLocalizedString("status_loading", comment: "Lexicon loading")
            statusLabel.isHidden = false
            candidatesStack.isHidden = true
            sep1.isHidden = true
            sep2.isHidden = true
            return
        case .failed:
            statusLabel.text = NSLocalizedString("status_failed", comment: "Lexicon failed to load")
            statusLabel.isHidden = false
            candidatesStack.isHidden = true
            sep1.isHidden = true
            sep2.isHidden = true
            return
        case .none:
            statusLabel.isHidden = true
            candidatesStack.isHidden = false
        }

        // Stock QuickType: 3 equal-width columns; hairlines drawn as overlays.
        // When the typed word is unknown, reserve the last column for "+ Add".
        let candidateLimit = canAddWord ? Self.candidateSlots - 1 : Self.candidateSlots
        var slots = Array(lastCandidates.prefix(candidateLimit))
        while slots.count < candidateLimit { slots.append("") }
        if canAddWord { slots.append(Self.addSlot) }
        slotWords = slots

        for (idx, button) in candidateButtons.enumerated() {
            let word = slots[idx]
            button.backgroundColor = palette.candidateBar
            if word == Self.addSlot {
                button.setTitle(NSLocalizedString("candidate_add", comment: "Add unknown word"), for: .normal)
                button.titleLabel?.font = candidateFont(emphasized: false, add: true)
                button.setTitleColor(palette.candidateSecondary, for: .normal)
                button.setTitleColor(palette.candidateSecondary.withAlphaComponent(0.55), for: .highlighted)
                button.isEnabled = true
                button.accessibilityLabel = NSLocalizedString("a11y_add_word", comment: "")
                button.isAccessibilityElement = true
            } else {
                let emphasized = idx == 0 && !word.isEmpty
                let color: UIColor = word.isEmpty
                    ? .clear
                    : (lastMisspelled && idx == 0 ? palette.misspelled : palette.candidateText)
                button.setTitle(word.isEmpty ? " " : word, for: .normal)
                button.titleLabel?.font = candidateFont(emphasized: emphasized, add: false)
                button.setTitleColor(color, for: .normal)
                button.setTitleColor(color.withAlphaComponent(0.55), for: .highlighted)
                button.isEnabled = !word.isEmpty
                button.accessibilityLabel = word
                button.isAccessibilityElement = !word.isEmpty
            }
        }
        let hasAny = slots.contains { !$0.isEmpty }
        sep1.isHidden = !hasAny
        sep2.isHidden = !hasAny
    }

    @objc private func candidateTapped(_ sender: UIButton) {
        guard sender.tag < slotWords.count else { return }
        let word = slotWords[sender.tag]
        if word == Self.addSlot {
            if hapticsEnabled { haptic.impactOccurred() }
            delegate?.keyboardViewDidTapAddWord(self)
        } else if !word.isEmpty {
            playClick()
            delegate?.keyboardView(self, didSelectCandidate: word)
        }
    }

    // MARK: - Layout

    private func setup() {
        chromeFill.translatesAutoresizingMaskIntoConstraints = false
        candidateBar.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false

        candidatesStack.axis = .horizontal
        candidatesStack.alignment = .fill
        candidatesStack.spacing = 0
        candidatesStack.distribution = .fillEqually
        candidatesStack.translatesAutoresizingMaskIntoConstraints = false
        for idx in 0..<Self.candidateSlots {
            let button = UIButton(type: .custom)
            button.tag = idx
            button.isOpaque = true
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
            button.accessibilityTraits = [.button, .keyboardKey]
            button.addTarget(self, action: #selector(candidateTapped(_:)), for: .touchUpInside)
            candidateButtons.append(button)
            candidatesStack.addArrangedSubview(button)
        }

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.isHidden = true
        statusLabel.isOpaque = true

        for sep in [sep1, sep2] {
            sep.translatesAutoresizingMaskIntoConstraints = false
            sep.isOpaque = true
            sep.isHidden = true
            sep.isUserInteractionEnabled = false
        }

        candidateBar.addSubview(candidatesStack)
        // Hairlines ride on the left edge of columns 2 and 3 so they follow safe-area insets.
        candidateButtons[1].addSubview(sep1)
        candidateButtons[2].addSubview(sep2)
        candidateBar.addSubview(statusLabel)

        rowsStack.axis = .vertical
        rowsStack.spacing = 7
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        // Equal rows fill the shell — heightScale changes shell → keys grow/shrink.
        rowsStack.distribution = .fillEqually

        addSubview(chromeFill)
        addSubview(candidateBar)
        addSubview(divider)
        addSubview(rowsStack)

        let hairline = 1 / max(UIScreen.main.scale, 2)
        let chromeH = chromeFill.heightAnchor.constraint(equalToConstant: 8)
        let candH = candidateBar.heightAnchor.constraint(equalToConstant: 36)
        let rowsTop = rowsStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 8)
        let rowsBottom = rowsStack.bottomAnchor.constraint(
            equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -5
        )
        // Safe area keeps keys clear of the notch / Dynamic Island in landscape, like the stock keyboard.
        let rowsLeading = rowsStack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 3)
        let rowsTrailing = rowsStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -3)
        chromeHeightConstraint = chromeH
        candidateHeightConstraint = candH
        rowsTopConstraint = rowsTop
        rowsBottomConstraint = rowsBottom
        rowsLeadingConstraint = rowsLeading
        rowsTrailingConstraint = rowsTrailing

        NSLayoutConstraint.activate([
            chromeFill.topAnchor.constraint(equalTo: topAnchor),
            chromeFill.leadingAnchor.constraint(equalTo: leadingAnchor),
            chromeFill.trailingAnchor.constraint(equalTo: trailingAnchor),
            chromeH,

            candidateBar.topAnchor.constraint(equalTo: chromeFill.bottomAnchor),
            candidateBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            candidateBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            candH,

            candidatesStack.leadingAnchor.constraint(equalTo: candidateBar.safeAreaLayoutGuide.leadingAnchor),
            candidatesStack.trailingAnchor.constraint(equalTo: candidateBar.safeAreaLayoutGuide.trailingAnchor),
            candidatesStack.topAnchor.constraint(equalTo: candidateBar.topAnchor),
            candidatesStack.bottomAnchor.constraint(equalTo: candidateBar.bottomAnchor),

            sep1.widthAnchor.constraint(equalToConstant: hairline),
            sep1.heightAnchor.constraint(equalToConstant: 20),
            sep1.centerYAnchor.constraint(equalTo: candidateButtons[1].centerYAnchor),
            sep1.centerXAnchor.constraint(equalTo: candidateButtons[1].leadingAnchor),

            sep2.widthAnchor.constraint(equalToConstant: hairline),
            sep2.heightAnchor.constraint(equalToConstant: 20),
            sep2.centerYAnchor.constraint(equalTo: candidateButtons[2].centerYAnchor),
            sep2.centerXAnchor.constraint(equalTo: candidateButtons[2].leadingAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: candidateBar.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: candidateBar.trailingAnchor, constant: -12),
            statusLabel.centerYAnchor.constraint(equalTo: candidateBar.centerYAnchor),

            divider.topAnchor.constraint(equalTo: candidateBar.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: hairline),

            rowsTop,
            rowsLeading,
            rowsTrailing,
            rowsBottom,
        ])
        applyHeightMetrics(traits: traitCollection)
    }

    /// Full rebuild — only for layer / layout / metric changes. Shift and return-key updates
    /// go through `refreshKeyFaces()`.
    private func rebuildKeys() {
        resetTransientState()
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        keyButtons.removeAll()
        let keySpacing = ((isRegularWidth ? 9 : 6) * min(max(heightScale, 0.85), 1.2)).rounded()
        for row in keyRows() {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = keySpacing
            stack.distribution = .fill
            stack.alignment = .fill

            var letterRef: UIView?
            for item in row {
                let view = makeKeyView(item)
                stack.addArrangedSubview(view)
                if item.flex == 1, letterRef == nil, !item.title.isEmpty || item.usesSymbol {
                    letterRef = view
                }
            }

            if let unit = letterRef ?? stack.arrangedSubviews.first {
                for (item, view) in zip(row, stack.arrangedSubviews) where view !== unit {
                    let c = view.widthAnchor.constraint(equalTo: unit.widthAnchor, multiplier: item.flex)
                    c.priority = .defaultHigh
                    c.isActive = true
                }
            }

            rowsStack.addArrangedSubview(stack)
        }
        refreshKeyFaces()
    }

    // MARK: - Key model

    fileprivate struct KeyItem {
        /// Lowercase base title for letters (cased at display time); literal otherwise.
        let title: String
        let key: Key
        let longPress: [String]
        let flex: CGFloat
        let usesSymbol: Bool
        var isLetter = false
    }

    private func keyRows() -> [[KeyItem]] {
        switch layerMode {
        case .letters: return letterRows()
        case .symbols: return symbolRows()
        case .uly: return ulyRows()
        }
    }

    private func letter(_ c: String, _ long: [String] = []) -> KeyItem {
        KeyItem(title: c, key: .char(c), longPress: long, flex: 1, usesSymbol: false, isLetter: true)
    }

    private func letterRows() -> [[KeyItem]] {
        let long: [Character: [String]] = [
            "e": ["ë"], "u": ["ü"], "o": ["ö"],
            "s": ["sh"], "g": ["gh"], "z": ["zh"], "c": ["ch"], "n": ["ng"],
        ]
        let row = { (chars: String) in chars.map { self.letter(String($0), long[$0] ?? []) } }
        if isRegularWidth {
            // Stock iPad: delete ends row 1, return ends row 2, shift on both sides of row 3.
            let r1 = row("qwertyuiop") + [backspaceKey(flex: 1.5)]
            let r2 = [insetSpacer(0.5)] + row("asdfghjkl") + [returnKey(flex: 2)]
            let r3 = [KeyItem(title: "shift", key: .shift, longPress: [], flex: 1.25, usesSymbol: true)]
                + row("zxcvbnm")
                + [plain(",", long: ["!"]), plain(".", long: ["?"])]
                + [KeyItem(title: "shift", key: .shift, longPress: [], flex: 1.6, usesSymbol: true)]
            var r4: [KeyItem] = [KeyItem(title: "123", key: .symbols, longPress: [], flex: 1.5, usesSymbol: false)]
            if showGlobe {
                r4.append(KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: 1, usesSymbol: true))
            }
            r4.append(KeyItem(title: "ëöü", key: .uly, longPress: ["'"], flex: 1, usesSymbol: false))
            r4.append(contentsOf: padSpaceRow(trailing: KeyItem(title: "123", key: .symbols, longPress: [], flex: 1.5, usesSymbol: false)))
            return [r1, r2, r3, r4]
        }
        let inset: CGFloat = 0.4
        let r1 = row("qwertyuiop")
        let r2 = [insetSpacer(inset)] + row("asdfghjkl") + [insetSpacer(inset)]
        let r3 = [KeyItem(title: "shift", key: .shift, longPress: [], flex: 1.35, usesSymbol: true)]
            + row("zxcvbnm")
            + [KeyItem(title: "delete.left", key: .backspace, longPress: [], flex: 1.35, usesSymbol: true)]
        var r4: [KeyItem] = [
            KeyItem(title: "123", key: .symbols, longPress: [], flex: 1.25, usesSymbol: false),
        ]
        if showGlobe {
            r4.append(KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: 1.1, usesSymbol: true))
        }
        r4.append(KeyItem(title: "ëöü", key: .uly, longPress: ["'"], flex: 1.15, usesSymbol: false))
        r4.append(contentsOf: spaceRow())
        return [r1, r2, r3, r4]
    }

    /// Space (+ field-specific keys) and return.
    private func spaceRow() -> [KeyItem] {
        var spaceFlex: CGFloat = showGlobe ? 4.6 : 5.7
        var out: [KeyItem] = []
        let extras: (String, String)? = {
            switch fieldKind {
            case .text: return nil
            case .email: return ("@", ".")
            case .url: return ("/", ".")
            }
        }()
        if let extras {
            spaceFlex -= 2
            out.append(KeyItem(title: extras.0, key: .char(extras.0), longPress: [], flex: 1, usesSymbol: false))
            out.append(KeyItem(title: "space", key: .space, longPress: [], flex: spaceFlex, usesSymbol: false))
            out.append(KeyItem(title: extras.1, key: .char(extras.1), longPress: [], flex: 1, usesSymbol: false))
        } else {
            out.append(KeyItem(title: "space", key: .space, longPress: [], flex: spaceFlex, usesSymbol: false))
        }
        out.append(KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.45, usesSymbol: false))
        return out
    }

    /// iPad bottom row: space (+ field extras), a trailing layer key and the hide-keyboard key.
    private func padSpaceRow(trailing: KeyItem) -> [KeyItem] {
        var spaceFlex: CGFloat = showGlobe ? 5.5 : 6.5
        var out: [KeyItem] = []
        switch fieldKind {
        case .text:
            out.append(KeyItem(title: "space", key: .space, longPress: [], flex: spaceFlex, usesSymbol: false))
        case .email, .url:
            let lead = fieldKind == .email ? "@" : "/"
            spaceFlex -= 2
            out.append(plain(lead))
            out.append(KeyItem(title: "space", key: .space, longPress: [], flex: spaceFlex, usesSymbol: false))
            out.append(plain("."))
        }
        out.append(trailing)
        out.append(KeyItem(title: "keyboard.chevron.compact.down", key: .dismiss, longPress: [], flex: 1, usesSymbol: true))
        return out
    }

    private func backspaceKey(flex: CGFloat) -> KeyItem {
        KeyItem(title: "delete.left", key: .backspace, longPress: [], flex: flex, usesSymbol: true)
    }

    private func returnKey(flex: CGFloat) -> KeyItem {
        KeyItem(title: "return", key: .returnKey, longPress: [], flex: flex, usesSymbol: false)
    }

    private func insetSpacer(_ flex: CGFloat) -> KeyItem {
        KeyItem(title: "", key: .char(""), longPress: [], flex: flex, usesSymbol: false)
    }

    private func plain(_ s: String, flex: CGFloat = 1, long: [String] = []) -> KeyItem {
        KeyItem(title: s, key: .char(s), longPress: long, flex: flex, usesSymbol: false)
    }

    private func bottomRow() -> [KeyItem] {
        let abc = KeyItem(title: "ABC", key: .letters, longPress: [], flex: isRegularWidth ? 1.5 : 1.25, usesSymbol: false)
        var bottom: [KeyItem] = [abc]
        if showGlobe {
            bottom.append(KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: isRegularWidth ? 1 : 1.1, usesSymbol: true))
        }
        bottom.append(contentsOf: isRegularWidth ? padSpaceRow(trailing: abc) : spaceRow())
        return bottom
    }

    private func symbolRows() -> [[KeyItem]] {
        if isRegularWidth {
            return [
                "1234567890".map { plain(String($0)) } + [backspaceKey(flex: 1.5)],
                [insetSpacer(0.5)] + "-/:;()$&@".map { plain(String($0)) } + [returnKey(flex: 2)],
                [KeyItem(title: "#+=", key: .uly, longPress: [], flex: 1.25, usesSymbol: false)]
                    + [".", ",", "?", "!", "'", "\""].map { plain($0) }
                    + [KeyItem(title: "#+=", key: .uly, longPress: [], flex: 1.6, usesSymbol: false)],
                bottomRow(),
            ]
        }
        return [
            "1234567890".map { plain(String($0)) },
            "-/:;()$&@\"".map { plain(String($0)) },
            [KeyItem(title: "#+=", key: .uly, longPress: [], flex: 1.3, usesSymbol: false)]
                + [".", ",", "?", "!", "'"].map { plain($0) }
                + [backspaceKey(flex: 1.3)],
            bottomRow(),
        ]
    }

    private func ulyRows() -> [[KeyItem]] {
        let top = ["ë", "ö", "ü", "Ë", "Ö", "Ü", "ch", "sh", "zh", "gh"].map { plain($0) }
        let punct = ["ng", "'", "-", ",", "."].map { plain($0) }
        if isRegularWidth {
            return [
                top + [backspaceKey(flex: 1.5)],
                [insetSpacer(0.5)] + punct + [returnKey(flex: 2)],
                bottomRow(),
            ]
        }
        return [
            top,
            punct + [backspaceKey(flex: 1.3)],
            bottomRow(),
        ]
    }

    private func cased(_ s: String) -> String {
        if capsLocked { return s.uppercased() }
        guard shiftOn, let first = s.first else { return s }
        return String(first).uppercased() + s.dropFirst()
    }

    private func isSpecial(_ key: Key) -> Bool {
        if case .char = key { return false }
        return true
    }

    // MARK: - Key views

    private func makeKeyView(_ item: KeyItem) -> UIView {
        if item.title.isEmpty && item.key == .char("") {
            let spacer = UIView()
            spacer.isUserInteractionEnabled = false
            spacer.isAccessibilityElement = false
            spacer.backgroundColor = .clear
            return spacer
        }

        let btn = KeyButton(type: .custom)
        btn.item = item
        btn.configuration = nil
        btn.isOpaque = true
        btn.layer.cornerRadius = isRegularWidth ? 7 : 5
        btn.layer.cornerCurve = .continuous
        btn.layer.shadowOpacity = 1
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius = 0
        btn.clipsToBounds = false
        btn.isAccessibilityElement = true
        btn.accessibilityTraits = [.keyboardKey]
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.minimumScaleFactor = 0.6

        switch item.key {
        case .backspace:
            btn.addTarget(self, action: #selector(deleteDown(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(deleteUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        case .char(""):
            break
        default:
            btn.addTarget(self, action: #selector(keyDown(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(keyUp(_:)), for: .touchUpInside)
            btn.addTarget(self, action: #selector(keyAbandoned(_:)), for: [.touchUpOutside, .touchCancel, .touchDragExit])
        }

        if !item.longPress.isEmpty {
            let long = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            long.minimumPressDuration = 0.35
            long.cancelsTouchesInView = true
            btn.addGestureRecognizer(long)
            // VoiceOver cannot slide through the popup; expose each alternate as an action.
            btn.accessibilityCustomActions = item.longPress.map { option in
                UIAccessibilityCustomAction(name: option) { [weak self] _ in
                    guard let self else { return false }
                    let text = item.isLetter || option.first?.isLetter == true ? self.cased(option) : option
                    self.delegate?.keyboardView(self, didTapKey: .char(text))
                    return true
                }
            }
        }

        if item.key == .shift {
            let long = UILongPressGestureRecognizer(target: self, action: #selector(handleShiftLongPress(_:)))
            long.minimumPressDuration = 0.45
            long.cancelsTouchesInView = true
            btn.addGestureRecognizer(long)
            btn.accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: NSLocalizedString("a11y_caps_lock", comment: "")) { [weak self] _ in
                    guard let self else { return false }
                    self.delegate?.keyboardView(self, didTapKey: .capsLock)
                    return true
                },
            ]
        }

        keyButtons.append(btn)
        return btn
    }

    /// Long-press Shift toggles Caps Lock (like double-tap).
    @objc private func handleShiftLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        lastShiftTapAt = 0
        if hapticsEnabled { haptic.impactOccurred() }
        delegate?.keyboardView(self, didTapKey: .capsLock)
    }

    /// Update titles, icons and colors in place (shift, caps lock, return key, theme).
    private func refreshKeyFaces() {
        let glyphScale = min(max(heightScale, 0.88), 1.2)
        for btn in keyButtons {
            guard let item = btn.item else { continue }
            let special = isSpecial(item.key)
            var background = special ? palette.keySpecial : palette.keyFace
            var textColor = palette.keyText

            if item.key == .shift {
                let symbol = capsLocked ? "capslock.fill" : (shiftOn ? "shift.fill" : "shift")
                setSymbol(symbol, on: btn, scale: glyphScale)
                if shiftOn || capsLocked { background = palette.keyFace }
                btn.accessibilityLabel = NSLocalizedString(capsLocked ? "a11y_caps_lock" : "a11y_shift", comment: "")
                btn.accessibilityTraits = shiftOn || capsLocked ? [.keyboardKey, .selected] : [.keyboardKey]
            } else if item.usesSymbol {
                setSymbol(item.title, on: btn, scale: glyphScale)
                btn.accessibilityLabel = accessibilityName(for: item.key)
            } else {
                let title: String
                switch item.key {
                case .space: title = NSLocalizedString("key_space", comment: "Space bar label")
                case .returnKey:
                    title = returnTitle
                    if returnEmphasized {
                        background = .systemBlue
                        textColor = .white
                    }
                default: title = item.isLetter ? cased(item.title) : item.title
                }
                btn.setImage(nil, for: .normal)
                btn.setTitle(title, for: .normal)
                let base: CGFloat
                if item.key == .space || item.key == .returnKey {
                    base = 15
                } else {
                    base = title.count > 2 ? 15 : (title.count == 2 ? 17 : (isRegularWidth ? 24 : 22.5))
                }
                btn.titleLabel?.font = .systemFont(ofSize: (base * glyphScale).rounded(), weight: .regular)
                btn.setTitleColor(textColor, for: .normal)
                btn.accessibilityLabel = isSpecial(item.key) ? accessibilityName(for: item.key) : title
            }
            btn.restingColor = background
            btn.backgroundColor = background
            btn.layer.shadowColor = palette.keyShadow.cgColor
            btn.tintColor = textColor
        }
    }

    private func setSymbol(_ name: String, on btn: UIButton, scale: CGFloat) {
        let pt = (17 * scale).rounded()
        let img = UIImage(systemName: name)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: pt, weight: .regular))
        btn.setImage(img, for: .normal)
        btn.setTitle(nil, for: .normal)
    }

    private func accessibilityName(for key: Key) -> String? {
        let k: String
        switch key {
        case .backspace, .deleteWord: k = "a11y_delete"
        case .space: k = "a11y_space"
        case .returnKey: return returnTitle
        case .shift: k = "a11y_shift"
        case .capsLock: k = "a11y_caps_lock"
        case .symbols: k = "a11y_symbols"
        case .letters: k = "a11y_letters"
        case .uly: k = "a11y_uly"
        case .nextKeyboard: k = "a11y_next_keyboard"
        case .dismiss: k = "a11y_dismiss"
        case .char(let s): return s
        }
        return NSLocalizedString(k, comment: "")
    }

    // MARK: - Touch handling

    private func playClick() {
        if soundEnabled { UIDevice.current.playInputClick() }
    }

    private func pressFeedback() {
        playClick()
        if hapticsEnabled {
            haptic.impactOccurred()
            haptic.prepare()
        }
    }

    @objc private func keyDown(_ btn: KeyButton) {
        pressFeedback()
        btn.backgroundColor = btn.item.map { isSpecial($0.key) } == true
            ? palette.keyFace
            : palette.keySpecial.withAlphaComponent(0.55)
        if let item = btn.item, !isSpecial(item.key) {
            showKeyPreview(for: btn)
        }
    }

    @objc private func keyAbandoned(_ btn: KeyButton) {
        btn.backgroundColor = btn.restingColor
        hideKeyPreview()
    }

    @objc private func keyUp(_ btn: KeyButton) {
        btn.backgroundColor = btn.restingColor
        hideKeyPreview()
        guard popup == nil, let item = btn.item else { return }
        switch item.key {
        case .char(let s) where item.isLetter:
            delegate?.keyboardView(self, didTapKey: .char(cased(s)))
        case .shift:
            let now = CACurrentMediaTime()
            if now - lastShiftTapAt < 0.35 {
                lastShiftTapAt = 0
                delegate?.keyboardView(self, didTapKey: .capsLock)
            } else {
                lastShiftTapAt = now
                delegate?.keyboardView(self, didTapKey: .shift)
            }
        default:
            delegate?.keyboardView(self, didTapKey: item.key)
        }
    }

    // Backspace: delete on touch-down, repeat after 0.4 s (accelerating), words after 1.5 s.

    @objc private func deleteDown(_ btn: KeyButton) {
        pressFeedback()
        btn.backgroundColor = palette.keyFace
        endDeleteRepeat()
        deleteStartedAt = CACurrentMediaTime()
        delegate?.keyboardView(self, didTapKey: .backspace)
        scheduleDeleteTick(after: 0.4)
    }

    @objc private func deleteUp(_ btn: KeyButton) {
        btn.backgroundColor = btn.restingColor
        endDeleteRepeat()
    }

    private func scheduleDeleteTick(after interval: TimeInterval) {
        deleteTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.deleteTick()
        }
    }

    private func deleteTick() {
        let held = CACurrentMediaTime() - deleteStartedAt
        playClick()
        if held >= 1.5 {
            delegate?.keyboardView(self, didTapKey: .deleteWord)
            scheduleDeleteTick(after: 0.28)
        } else {
            delegate?.keyboardView(self, didTapKey: .backspace)
            scheduleDeleteTick(after: max(0.05, 0.11 - (held - 0.4) * 0.06))
        }
    }

    private func endDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    // MARK: - Key preview

    private func showKeyPreview(for btn: KeyButton) {
        hideKeyPreview()
        guard !isRegularWidth, let title = btn.title(for: .normal), title.count <= 2 else { return }
        let keyFrame = btn.convert(btn.bounds, to: self)
        let width = max(keyFrame.width + 16, 44)
        let height = keyFrame.height * 1.15
        var x = keyFrame.midX - width / 2
        x = min(max(2, x), bounds.width - width - 2)
        let y = max(0, keyFrame.minY - height - 4)

        let bubble = UIView(frame: CGRect(x: x, y: y, width: width, height: height))
        bubble.backgroundColor = palette.keyFace
        bubble.layer.cornerRadius = 8
        bubble.layer.cornerCurve = .continuous
        bubble.layer.shadowColor = UIColor.black.cgColor
        bubble.layer.shadowOpacity = 0.28
        bubble.layer.shadowRadius = 3
        bubble.layer.shadowOffset = CGSize(width: 0, height: 1)
        bubble.isUserInteractionEnabled = false

        let label = UILabel(frame: bubble.bounds)
        label.text = title
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 32, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = palette.keyText
        bubble.addSubview(label)
        addSubview(bubble)
        keyPreview = bubble
    }

    private func hideKeyPreview() {
        keyPreview?.removeFromSuperview()
        keyPreview = nil
    }

    // MARK: - Long-press alternates (slide to select, release to commit)

    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard let btn = gr.view as? KeyButton, let item = btn.item else { return }
        switch gr.state {
        case .began:
            hideKeyPreview()
            btn.backgroundColor = btn.restingColor
            let options = item.longPress.map { item.isLetter || $0.first?.isLetter == true ? cased($0) : $0 }
            showPopup(options: options, from: btn)
            updatePopupSelection(at: gr.location(in: self))
            if hapticsEnabled { haptic.impactOccurred() }
        case .changed:
            updatePopupSelection(at: gr.location(in: self))
        case .ended:
            let chosen = popupOptions.indices.contains(popupSelection) ? popupOptions[popupSelection] : nil
            hidePopup()
            if let chosen {
                playClick()
                delegate?.keyboardView(self, didTapKey: .char(chosen))
            }
        default:
            hidePopup()
        }
    }

    private func showPopup(options: [String], from btn: UIButton) {
        hidePopup()
        guard !options.isEmpty else { return }
        let keyFrame = btn.convert(btn.bounds, to: self)
        let cellW = max(keyFrame.width, 40)
        let cellH = max(keyFrame.height, 40)
        let margin: CGFloat = 5
        let width = cellW * CGFloat(options.count) + margin * 2
        let height = cellH + margin * 2
        var x = keyFrame.midX - width / 2
        x = min(max(2, x), bounds.width - width - 2)
        let y = max(0, keyFrame.minY - height - 4)

        let container = UIView(frame: CGRect(x: x, y: y, width: width, height: height))
        container.backgroundColor = palette.popupBackground
        container.layer.cornerRadius = 9
        container.layer.cornerCurve = .continuous
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.isUserInteractionEnabled = false

        popupLabels = options.enumerated().map { idx, opt in
            let label = UILabel(frame: CGRect(x: margin + CGFloat(idx) * cellW, y: margin, width: cellW, height: cellH))
            label.text = opt
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 22)
            label.textColor = palette.keyText
            label.layer.cornerRadius = 6
            label.layer.masksToBounds = true
            container.addSubview(label)
            return label
        }
        popupOptions = options
        popupSelection = 0
        addSubview(container)
        popup = container
        renderPopupSelection()
    }

    private func updatePopupSelection(at point: CGPoint) {
        guard let popup, !popupLabels.isEmpty else { return }
        let local = point.x - popup.frame.minX - 5
        let cellW = popupLabels[0].frame.width
        let idx = min(max(Int(floor(local / cellW)), 0), popupLabels.count - 1)
        guard idx != popupSelection else { return }
        popupSelection = idx
        renderPopupSelection()
    }

    private func renderPopupSelection() {
        for (idx, label) in popupLabels.enumerated() {
            let selected = idx == popupSelection
            label.backgroundColor = selected ? .systemBlue : .clear
            label.textColor = selected ? .white : palette.keyText
        }
    }

    private func hidePopup() {
        popup?.removeFromSuperview()
        popup = nil
        popupLabels = []
        popupOptions = []
    }
}

/// Key button that remembers its model and resting color (for press highlight).
private final class KeyButton: UIButton {
    var item: KeyboardView.KeyItem?
    var restingColor: UIColor?
}
