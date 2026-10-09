import ObjectiveC
import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, didTapKey key: KeyboardView.Key)
    func keyboardView(_ view: KeyboardView, didSelectCandidate word: String)
    func keyboardViewDidChangeTheme(_ view: KeyboardView)
}

final class KeyboardView: UIView {
    enum Layer { case letters, symbols, uly }
    enum Key: Equatable {
        case char(String)
        case backspace, space, returnKey, shift, symbols, uly, letters, nextKeyboard, theme
    }

    weak var delegate: KeyboardViewDelegate?

    private let candidateBar = UIView()
    private let candidatesStack = UIStackView()
    private let themeButton = UIButton(type: .system)
    private let rowsStack = UIStackView()
    private var shiftOn = false
    private var layerMode: Layer = .letters
    private var popup: UIStackView?
    private var palette = KeyboardPalette.palette(style: .light)
    private var preference: KeyboardThemePreference = .system
    private var lastCandidates: [String] = []
    private var lastMisspelled = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        preference = KeyboardThemePreference.current
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
            updateCandidates(lastCandidates, misspelled: lastMisspelled)
        }
    }

    func setShift(_ on: Bool) {
        shiftOn = on
        rebuildKeys()
    }

    func setLayer(_ layer: Layer) {
        layerMode = layer
        rebuildKeys()
    }

    func applyTheme(traits: UITraitCollection) {
        let style = preference.resolvedStyle(for: traits)
        palette = KeyboardPalette.palette(style: style)
        backgroundColor = palette.background
        candidateBar.backgroundColor = palette.candidateBar
        themeButton.setTitleColor(palette.candidateSecondary, for: .normal)
        themeButton.setTitle(themeGlyph(), for: .normal)
    }

    func updateCandidates(_ words: [String], misspelled: Bool) {
        lastCandidates = words
        lastMisspelled = misspelled
        candidatesStack.arrangedSubviews.forEach {
            candidatesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let slots = Array(words.prefix(3))
        for idx in 0..<3 {
            let word = idx < slots.count ? slots[idx] : ""
            let wrap = UIView()
            let btn = UIButton(type: .system)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.setTitle(word.isEmpty ? " " : word, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.setTitleColor(
                word.isEmpty
                    ? .clear
                    : (misspelled && idx == 0 ? palette.misspelled : palette.candidateText),
                for: .normal
            )
            btn.isEnabled = !word.isEmpty
            if !word.isEmpty {
                btn.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    self.delegate?.keyboardView(self, didSelectCandidate: word)
                }, for: .touchUpInside)
            }
            wrap.addSubview(btn)
            NSLayoutConstraint.activate([
                btn.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
                btn.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
                btn.topAnchor.constraint(equalTo: wrap.topAnchor),
                btn.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
            ])
            if idx < 2 {
                let sep = UIView()
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.backgroundColor = palette.separator
                wrap.addSubview(sep)
                NSLayoutConstraint.activate([
                    sep.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
                    sep.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
                    sep.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
                    sep.heightAnchor.constraint(equalToConstant: 22),
                ])
            }
            candidatesStack.addArrangedSubview(wrap)
        }
    }

    private func setup() {
        candidateBar.translatesAutoresizingMaskIntoConstraints = false

        candidatesStack.axis = .horizontal
        candidatesStack.alignment = .center
        candidatesStack.spacing = 0
        candidatesStack.distribution = .fillEqually
        candidatesStack.translatesAutoresizingMaskIntoConstraints = false

        themeButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        themeButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.preference.cycle()
            KeyboardThemePreference.current = self.preference
            self.applyTheme(traits: self.traitCollection)
            self.rebuildKeys()
            self.updateCandidates(self.lastCandidates, misspelled: self.lastMisspelled)
            self.delegate?.keyboardViewDidChangeTheme(self)
        }, for: .touchUpInside)
        themeButton.translatesAutoresizingMaskIntoConstraints = false
        themeButton.accessibilityLabel = "Theme"

        candidateBar.addSubview(candidatesStack)
        candidateBar.addSubview(themeButton)

        rowsStack.axis = .vertical
        rowsStack.spacing = 10
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(candidateBar)
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            candidateBar.topAnchor.constraint(equalTo: topAnchor),
            candidateBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            candidateBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            candidateBar.heightAnchor.constraint(equalToConstant: 42),

            themeButton.trailingAnchor.constraint(equalTo: candidateBar.trailingAnchor, constant: -8),
            themeButton.centerYAnchor.constraint(equalTo: candidateBar.centerYAnchor),
            themeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),

            candidatesStack.leadingAnchor.constraint(equalTo: candidateBar.leadingAnchor, constant: 4),
            candidatesStack.trailingAnchor.constraint(equalTo: themeButton.leadingAnchor, constant: -4),
            candidatesStack.centerYAnchor.constraint(equalTo: candidateBar.centerYAnchor),

            rowsStack.topAnchor.constraint(equalTo: candidateBar.bottomAnchor, constant: 6),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            rowsStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -4),
        ])
    }

    private func themeGlyph() -> String {
        switch preference {
        case .system: return "◐"
        case .light: return "☀︎"
        case .dark: return "☾"
        }
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

            // Size keys relative to a unit (flex=1) letter key.
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
        let r4: [KeyItem] = [
            KeyItem(title: "123", key: .symbols, longPress: [], flex: 1.25, usesSymbol: false),
            KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: 1.1, usesSymbol: true),
            KeyItem(title: "ëöü", key: .uly, longPress: ["'"], flex: 1.15, usesSymbol: false),
            KeyItem(title: "space", key: .space, longPress: [], flex: 4.6, usesSymbol: false),
            KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.45, usesSymbol: false),
        ]
        return [r1, r2, r3, r4]
    }

    /// Invisible flex spacer to indent the A-row like the system keyboard.
    private func insetSpacer(_ flex: CGFloat) -> KeyItem {
        KeyItem(title: "", key: .char(""), longPress: [], flex: flex, usesSymbol: false)
    }

    private func symbolRows() -> [[KeyItem]] {
        [
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
            [
                KeyItem(title: "ABC", key: .letters, longPress: [], flex: 1.25, usesSymbol: false),
                KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: 1.1, usesSymbol: true),
                KeyItem(title: "space", key: .space, longPress: [], flex: 4.6, usesSymbol: false),
                KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.45, usesSymbol: false),
            ],
        ]
    }

    private func ulyRows() -> [[KeyItem]] {
        [
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
            [
                KeyItem(title: "ABC", key: .letters, longPress: [], flex: 1.25, usesSymbol: false),
                KeyItem(title: "globe", key: .nextKeyboard, longPress: [], flex: 1.1, usesSymbol: true),
                KeyItem(title: "space", key: .space, longPress: [], flex: 4.6, usesSymbol: false),
                KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.45, usesSymbol: false),
            ],
        ]
    }

    private func cas(_ s: String) -> String {
        shiftOn ? s.uppercased() : s
    }

    private func makeButton(_ item: KeyItem) -> UIView {
        // Spacer for A-row indent
        if item.title.isEmpty && item.key == .char("") {
            let spacer = UIView()
            spacer.isUserInteractionEnabled = false
            spacer.backgroundColor = .clear
            return spacer
        }

        let btn = UIButton(type: .system)
        btn.configuration = nil
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
            let b = UIButton(type: .system)
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
