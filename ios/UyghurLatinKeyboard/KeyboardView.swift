import ObjectiveC
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
        case backspace, space, returnKey, shift, symbols, uly, letters, nextKeyboard
    }

    enum Status {
        case none
        case loading
        case failed
    }

    weak var delegate: KeyboardViewDelegate?

    /// Solid fill under the system rounded top so backdrop blur cannot show through.
    private let chromeFill = UIView()
    private let candidateBar = UIView()
    private let candidatesStack = UIStackView()
    private let sep1 = UIView()
    private let sep2 = UIView()
    private let statusLabel = UILabel()
    private let divider = UIView()
    private let rowsStack = UIStackView()
    private var shiftOn = false
    private var layerMode: Layer = .letters
    private var popup: UIStackView?
    private var palette = KeyboardPalette.palette(style: .light)
    private var preference: KeyboardThemePreference = .system
    private var lastCandidates: [String] = []
    private var lastMisspelled = false
    private var canAddWord = false
    private var showGlobe = true
    private var status: Status = .none

    override init(frame: CGRect) {
        super.init(frame: frame)
        preference = KeyboardPreferences.theme
        setup()
        applyTheme(traits: traitCollection)
        rebuildKeys()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if preference == .system {
            applyTheme(traits: traitCollection)
            rebuildKeys()
            applyCandidatePresentation()
        }
    }

    func reloadPreferences(traits: UITraitCollection) {
        preference = KeyboardPreferences.theme
        applyTheme(traits: traits)
        rebuildKeys()
    }

    func setShift(_ on: Bool) {
        shiftOn = on
        rebuildKeys()
    }

    func setLayer(_ layer: Layer) {
        layerMode = layer
        rebuildKeys()
    }

    func setNeedsInputModeSwitchKey(_ needs: Bool) {
        guard showGlobe != needs else { return }
        showGlobe = needs
        rebuildKeys()
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

    private func applyCandidatePresentation() {
        candidatesStack.arrangedSubviews.forEach {
            candidatesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        switch status {
        case .loading:
            statusLabel.text = "…"
            statusLabel.isHidden = false
            candidatesStack.isHidden = true
            return
        case .failed:
            statusLabel.text = "lexicon?"
            statusLabel.isHidden = false
            candidatesStack.isHidden = true
            return
        case .none:
            statusLabel.isHidden = true
            candidatesStack.isHidden = false
        }

        // Stock QuickType: 3 equal-width columns; hairlines drawn as overlays.
        // When the typed word is unknown, reserve the last column for "+ Add".
        let candidateLimit = canAddWord ? 2 : 3
        var slots = Array(lastCandidates.prefix(candidateLimit))
        while slots.count < candidateLimit { slots.append("") }
        if canAddWord { slots.append("__add__") }
        while slots.count < 3 { slots.append("") }

        for idx in 0..<3 {
            let word = slots[idx]
            if word == "__add__" {
                candidatesStack.addArrangedSubview(makeAddWordCell())
            } else {
                candidatesStack.addArrangedSubview(
                    makeCandidateCell(
                        word: word,
                        emphasized: idx == 0 && !word.isEmpty,
                        misspelled: lastMisspelled && idx == 0 && !word.isEmpty
                    )
                )
            }
        }
        let hasAny = slots.contains { !$0.isEmpty } || canAddWord
        sep1.isHidden = !hasAny
        sep2.isHidden = !hasAny
    }

    private func makeAddWordCell() -> UIView {
        let host = UIView()
        host.isOpaque = true
        host.backgroundColor = palette.candidateBar

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isOpaque = true
        button.backgroundColor = palette.candidateBar
        let title = NSLocalizedString("candidate_add", comment: "Add unknown word")
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.setTitleColor(palette.candidateSecondary, for: .normal)
        button.setTitleColor(palette.candidateSecondary.withAlphaComponent(0.55), for: .highlighted)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.delegate?.keyboardViewDidTapAddWord(self)
        }, for: .touchUpInside)

        host.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            button.topAnchor.constraint(equalTo: host.topAnchor),
            button.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        return host
    }

    private func makeCandidateCell(word: String, emphasized: Bool, misspelled: Bool) -> UIView {
        let host = UIView()
        host.isOpaque = true
        host.backgroundColor = palette.candidateBar

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isOpaque = true
        button.backgroundColor = palette.candidateBar
        button.setTitle(word.isEmpty ? " " : word, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: emphasized ? .semibold : .regular)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.textAlignment = .center
        let color: UIColor = word.isEmpty
            ? .clear
            : (misspelled ? palette.misspelled : palette.candidateText)
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(color.withAlphaComponent(0.55), for: .highlighted)
        button.isEnabled = !word.isEmpty
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        if !word.isEmpty {
            let selected = word
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.delegate?.keyboardView(self, didSelectCandidate: selected)
            }, for: .touchUpInside)
        }

        host.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            button.topAnchor.constraint(equalTo: host.topAnchor),
            button.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        return host
    }

    private func setup() {
        chromeFill.translatesAutoresizingMaskIntoConstraints = false
        candidateBar.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false

        candidatesStack.axis = .horizontal
        candidatesStack.alignment = .fill
        candidatesStack.spacing = 0
        candidatesStack.distribution = .fillEqually
        candidatesStack.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.isHidden = true
        statusLabel.isOpaque = true

        for sep in [sep1, sep2] {
            sep.translatesAutoresizingMaskIntoConstraints = false
            sep.isOpaque = true
            sep.isHidden = true
        }

        candidateBar.addSubview(candidatesStack)
        candidateBar.addSubview(sep1)
        candidateBar.addSubview(sep2)
        candidateBar.addSubview(statusLabel)

        rowsStack.axis = .vertical
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(chromeFill)
        addSubview(candidateBar)
        addSubview(divider)
        addSubview(rowsStack)

        let hairline = 1 / max(UIScreen.main.scale, 2)
        NSLayoutConstraint.activate([
            chromeFill.topAnchor.constraint(equalTo: topAnchor),
            chromeFill.leadingAnchor.constraint(equalTo: leadingAnchor),
            chromeFill.trailingAnchor.constraint(equalTo: trailingAnchor),
            chromeFill.heightAnchor.constraint(equalToConstant: 10),

            candidateBar.topAnchor.constraint(equalTo: chromeFill.bottomAnchor),
            candidateBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            candidateBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            candidateBar.heightAnchor.constraint(equalToConstant: 44),

            candidatesStack.leadingAnchor.constraint(equalTo: candidateBar.leadingAnchor),
            candidatesStack.trailingAnchor.constraint(equalTo: candidateBar.trailingAnchor),
            candidatesStack.topAnchor.constraint(equalTo: candidateBar.topAnchor),
            candidatesStack.bottomAnchor.constraint(equalTo: candidateBar.bottomAnchor),

            sep1.widthAnchor.constraint(equalToConstant: hairline),
            sep1.heightAnchor.constraint(equalToConstant: 22),
            sep1.centerYAnchor.constraint(equalTo: candidateBar.centerYAnchor),
            NSLayoutConstraint(
                item: sep1, attribute: .centerX, relatedBy: .equal,
                toItem: candidateBar, attribute: .trailing,
                multiplier: 1.0 / 3.0, constant: 0
            ),

            sep2.widthAnchor.constraint(equalToConstant: hairline),
            sep2.heightAnchor.constraint(equalToConstant: 22),
            sep2.centerYAnchor.constraint(equalTo: candidateBar.centerYAnchor),
            NSLayoutConstraint(
                item: sep2, attribute: .centerX, relatedBy: .equal,
                toItem: candidateBar, attribute: .trailing,
                multiplier: 2.0 / 3.0, constant: 0
            ),

            statusLabel.leadingAnchor.constraint(equalTo: candidateBar.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: candidateBar.trailingAnchor, constant: -12),
            statusLabel.centerYAnchor.constraint(equalTo: candidateBar.centerYAnchor),

            divider.topAnchor.constraint(equalTo: candidateBar.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: hairline),

            rowsStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 6),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            rowsStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -4),
        ])
    }

    private func rebuildKeys() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let rowHeight: CGFloat = traitCollection.horizontalSizeClass == .regular ? 54 : 42
        for row in keyRows() {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 6
            stack.distribution = .fill
            stack.alignment = .fill

            var letterRef: UIView?
            for item in row {
                let btn = makeButton(item)
                stack.addArrangedSubview(btn)
                if item.flex == 1, letterRef == nil, !item.title.isEmpty || item.usesSymbol {
                    letterRef = btn
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
            stack.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
        }
    }

    private struct KeyItem {
        let title: String
        let key: Key
        let longPress: [String]
        let flex: CGFloat
        let usesSymbol: Bool
    }

    private func keyRows() -> [[KeyItem]] {
        switch layerMode {
        case .letters: return letterRows()
        case .symbols: return symbolRows()
        case .uly: return ulyRows()
        }
    }

    private func letterRows() -> [[KeyItem]] {
        let r1 = "qwertyuiop".map { c -> KeyItem in
            let s = String(c)
            let shown = shiftOn ? s.uppercased() : s
            var long: [String] = []
            if c == "e" { long = ["ë", "Ë"] }
            if c == "u" { long = ["ü", "Ü"] }
            if c == "o" { long = ["ö", "Ö"] }
            return KeyItem(title: shown, key: .char(shown), longPress: long, flex: 1, usesSymbol: false)
        }
        let r2: [KeyItem] = [
            insetSpacer(0.4),
            KeyItem(title: cas("a"), key: .char(cas("a")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("s"), key: .char(cas("s")), longPress: ["sh"], flex: 1, usesSymbol: false),
            KeyItem(title: cas("d"), key: .char(cas("d")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("f"), key: .char(cas("f")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("g"), key: .char(cas("g")), longPress: ["gh"], flex: 1, usesSymbol: false),
            KeyItem(title: cas("h"), key: .char(cas("h")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("j"), key: .char(cas("j")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("k"), key: .char(cas("k")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("l"), key: .char(cas("l")), longPress: [], flex: 1, usesSymbol: false),
            insetSpacer(0.4),
        ]
        let r3: [KeyItem] = [
            KeyItem(title: "shift", key: .shift, longPress: [], flex: 1.35, usesSymbol: true),
            KeyItem(title: cas("z"), key: .char(cas("z")), longPress: ["zh"], flex: 1, usesSymbol: false),
            KeyItem(title: cas("x"), key: .char(cas("x")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("c"), key: .char(cas("c")), longPress: ["ch"], flex: 1, usesSymbol: false),
            KeyItem(title: cas("v"), key: .char(cas("v")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("b"), key: .char(cas("b")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: cas("n"), key: .char(cas("n")), longPress: ["ng"], flex: 1, usesSymbol: false),
            KeyItem(title: cas("m"), key: .char(cas("m")), longPress: [], flex: 1, usesSymbol: false),
            KeyItem(title: "delete.left", key: .backspace, longPress: [], flex: 1.35, usesSymbol: true),
        ]
        var r4: [KeyItem] = [
            KeyItem(title: "123", key: .symbols, longPress: [], flex: 1.25, usesSymbol: false),
        ]
        if showGlobe {
            r4.append(KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: 1.1, usesSymbol: true))
        }
        r4.append(contentsOf: [
            KeyItem(title: "ëöü", key: .uly, longPress: ["'"], flex: 1.15, usesSymbol: false),
            KeyItem(title: "space", key: .space, longPress: [], flex: showGlobe ? 4.6 : 5.7, usesSymbol: false),
            KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.45, usesSymbol: false),
        ])
        return [r1, r2, r3, r4]
    }

    private func insetSpacer(_ flex: CGFloat) -> KeyItem {
        KeyItem(title: "", key: .char(""), longPress: [], flex: flex, usesSymbol: false)
    }

    private func symbolRows() -> [[KeyItem]] {
        var bottom: [KeyItem] = [
            KeyItem(title: "ABC", key: .letters, longPress: [], flex: 1.25, usesSymbol: false),
        ]
        if showGlobe {
            bottom.append(KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: 1.1, usesSymbol: true))
        }
        bottom.append(contentsOf: [
            KeyItem(title: "space", key: .space, longPress: [], flex: showGlobe ? 4.6 : 5.7, usesSymbol: false),
            KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.45, usesSymbol: false),
        ])
        return [
            "1234567890".map { KeyItem(title: String($0), key: .char(String($0)), longPress: [], flex: 1, usesSymbol: false) },
            "-/:;()$&@\"".map { KeyItem(title: String($0), key: .char(String($0)), longPress: [], flex: 1, usesSymbol: false) },
            [
                KeyItem(title: "#+=", key: .uly, longPress: [], flex: 1.3, usesSymbol: false),
                KeyItem(title: ".", key: .char("."), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: ",", key: .char(","), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: "?", key: .char("?"), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: "!", key: .char("!"), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: "'", key: .char("'"), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: "delete.left", key: .backspace, longPress: [], flex: 1.3, usesSymbol: true),
            ],
            bottom,
        ]
    }

    private func ulyRows() -> [[KeyItem]] {
        var bottom: [KeyItem] = [
            KeyItem(title: "ABC", key: .letters, longPress: [], flex: 1.25, usesSymbol: false),
        ]
        if showGlobe {
            bottom.append(KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: 1.1, usesSymbol: true))
        }
        bottom.append(contentsOf: [
            KeyItem(title: "space", key: .space, longPress: [], flex: showGlobe ? 4.6 : 5.7, usesSymbol: false),
            KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.45, usesSymbol: false),
        ])
        return [
            ["ë", "ö", "ü", "Ë", "Ö", "Ü", "ch", "sh", "zh", "gh"].map {
                KeyItem(title: $0, key: .char($0), longPress: [], flex: 1, usesSymbol: false)
            },
            [
                KeyItem(title: "ng", key: .char("ng"), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: "'", key: .char("'"), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: "-", key: .char("-"), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: ",", key: .char(","), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: ".", key: .char("."), longPress: [], flex: 1, usesSymbol: false),
                KeyItem(title: "delete.left", key: .backspace, longPress: [], flex: 1.3, usesSymbol: true),
            ],
            bottom,
        ]
    }

    private func cas(_ s: String) -> String {
        shiftOn ? s.uppercased() : s
    }

    private func makeButton(_ item: KeyItem) -> UIView {
        if item.title.isEmpty && item.key == .char("") {
            let spacer = UIView()
            spacer.isUserInteractionEnabled = false
            spacer.backgroundColor = .clear
            return spacer
        }

        let btn = UIButton(type: .custom)
        btn.configuration = nil
        btn.isOpaque = true
        if item.usesSymbol, let img = UIImage(systemName: item.title) {
            btn.setImage(img.withConfiguration(UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)), for: .normal)
            btn.setTitle(nil, for: .normal)
            btn.tintColor = palette.keyText
        } else {
            btn.setTitle(item.title, for: .normal)
            btn.setImage(nil, for: .normal)
            let size: CGFloat = item.title.count > 2 ? 15 : (item.title.count == 2 ? 16 : 22)
            btn.titleLabel?.font = .systemFont(ofSize: size, weight: .regular)
            btn.setTitleColor(palette.keyText, for: .normal)
        }

        let special = isSpecial(item.key)
        btn.backgroundColor = special ? palette.keySpecial : palette.keyFace
        btn.layer.cornerRadius = 5.5
        btn.layer.shadowColor = palette.keyShadow.cgColor
        btn.layer.shadowOpacity = 1
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius = 0
        btn.clipsToBounds = false

        if shiftOn && item.key == .shift {
            btn.backgroundColor = palette.keyFace
        }

        let key = item.key
        if key != .char("") {
            btn.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.hidePopup()
                self.flash(btn)
                self.delegate?.keyboardView(self, didTapKey: key)
            }, for: .touchUpInside)
        }

        if !item.longPress.isEmpty {
            let long = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            long.minimumPressDuration = 0.35
            btn.addGestureRecognizer(long)
            objc_setAssociatedObject(btn, &AssociatedKeys.longPress, item.longPress, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        return btn
    }

    private func flash(_ btn: UIButton) {
        let original = btn.backgroundColor
        btn.backgroundColor = palette.keySpecial.withAlphaComponent(0.55)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            btn.backgroundColor = original
        }
    }

    private func isSpecial(_ key: Key) -> Bool {
        switch key {
        case .char: return false
        default: return true
        }
    }

    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began, let btn = gr.view as? UIButton,
              let options = objc_getAssociatedObject(btn, &AssociatedKeys.longPress) as? [String]
        else { return }
        showPopup(options: options, from: btn)
    }

    private func showPopup(options: [String], from btn: UIButton) {
        hidePopup()
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.isOpaque = true
        stack.backgroundColor = palette.popupBackground
        stack.layer.cornerRadius = 8
        stack.layer.shadowColor = UIColor.black.cgColor
        stack.layer.shadowOpacity = 0.25
        stack.layer.shadowOffset = CGSize(width: 0, height: 2)
        stack.layer.shadowRadius = 4
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        stack.translatesAutoresizingMaskIntoConstraints = false
        for opt in options {
            let b = UIButton(type: .custom)
            b.isOpaque = true
            b.setTitle(opt, for: .normal)
            b.setTitleColor(palette.keyText, for: .normal)
            b.backgroundColor = palette.keyFace
            b.layer.cornerRadius = 5
            b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            b.titleLabel?.font = .systemFont(ofSize: 20)
            b.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.hidePopup()
                self.delegate?.keyboardView(self, didTapKey: .char(opt))
            }, for: .touchUpInside)
            stack.addArrangedSubview(b)
        }
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: btn.topAnchor, constant: -8),
        ])
        popup = stack
    }

    private func hidePopup() {
        popup?.removeFromSuperview()
        popup = nil
    }
}

private enum AssociatedKeys {
    static var longPress = "longPressOptions"
}
