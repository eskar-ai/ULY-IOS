import ObjectiveC
import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, didTapKey key: KeyboardView.Key)
    func keyboardView(_ view: KeyboardView, didSelectCandidate word: String)
}

final class KeyboardView: UIView {
    enum Layer { case letters, symbols, uly }
    enum Key: Equatable {
        case char(String)
        case backspace, space, returnKey, shift, symbols, uly, letters, nextKeyboard
    }

    weak var delegate: KeyboardViewDelegate?

    private let candidatesStack = UIStackView()
    private let statusLabel = UILabel()
    private let rowsStack = UIStackView()
    private var shiftOn = false
    private var layer: Layer = .letters
    private var longPressWorkItem: DispatchWorkItem?
    private weak var longPressAnchor: UIButton?
    private var popup: UIStackView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        rebuildKeys()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStatus(_ text: String) {
        statusLabel.text = text
    }

    func setShift(_ on: Bool) {
        shiftOn = on
        rebuildKeys()
    }

    func setLayer(_ layer: Layer) {
        self.layer = layer
        rebuildKeys()
    }

    func updateCandidates(_ words: [String], misspelled: Bool) {
        candidatesStack.arrangedSubviews.forEach {
            candidatesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (idx, word) in words.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(word, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            btn.backgroundColor = idx == 0
                ? UIColor(red: 0.78, green: 0.90, blue: 0.86, alpha: 1)
                : UIColor.white.withAlphaComponent(0.12)
            btn.setTitleColor(idx == 0 ? .black : .white, for: .normal)
            btn.layer.cornerRadius = 14
            if misspelled {
                btn.layer.borderWidth = 1
                btn.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.7).cgColor
            }
            btn.addAction(UIAction { [weak self] _ in
                self?.delegate?.keyboardView(self!, didSelectCandidate: word)
            }, for: .touchUpInside)
            candidatesStack.addArrangedSubview(btn)
        }
    }

    private func setup() {
        backgroundColor = UIColor(red: 0.16, green: 0.25, blue: 0.22, alpha: 1)

        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        statusLabel.textAlignment = .center

        candidatesStack.axis = .horizontal
        candidatesStack.spacing = 6
        candidatesStack.alignment = .center

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        candidatesStack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(candidatesStack)

        rowsStack.axis = .vertical
        rowsStack.spacing = 6
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        let top = UIStackView(arrangedSubviews: [statusLabel, scroll])
        top.axis = .vertical
        top.spacing = 4
        top.translatesAutoresizingMaskIntoConstraints = false

        addSubview(top)
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            top.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            top.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),

            scroll.heightAnchor.constraint(equalToConstant: 36),
            candidatesStack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            candidatesStack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            candidatesStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            candidatesStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            candidatesStack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),

            rowsStack.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 6),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            rowsStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -4),
        ])
    }

    private func rebuildKeys() {
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for row in keyRows() {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 5
            stack.distribution = .fillEqually
            for item in row {
                stack.addArrangedSubview(makeButton(item))
            }
            rowsStack.addArrangedSubview(stack)
            stack.heightAnchor.constraint(equalToConstant: 42).isActive = true
        }
    }

    private struct KeyItem {
        let title: String
        let key: Key
        let longPress: [String]
        let flex: CGFloat
    }

    private func keyRows() -> [[KeyItem]] {
        switch layer {
        case .letters:
            return letterRows()
        case .symbols:
            return symbolRows()
        case .uly:
            return ulyRows()
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
            return KeyItem(title: shown, key: .char(shown), longPress: long, flex: 1)
        }
        let r2: [KeyItem] = [
            KeyItem(title: cas("a"), key: .char(cas("a")), longPress: [], flex: 1),
            KeyItem(title: cas("s"), key: .char(cas("s")), longPress: ["sh"], flex: 1),
            KeyItem(title: cas("d"), key: .char(cas("d")), longPress: [], flex: 1),
            KeyItem(title: cas("f"), key: .char(cas("f")), longPress: [], flex: 1),
            KeyItem(title: cas("g"), key: .char(cas("g")), longPress: ["gh"], flex: 1),
            KeyItem(title: cas("h"), key: .char(cas("h")), longPress: [], flex: 1),
            KeyItem(title: cas("j"), key: .char(cas("j")), longPress: [], flex: 1),
            KeyItem(title: cas("k"), key: .char(cas("k")), longPress: [], flex: 1),
            KeyItem(title: cas("l"), key: .char(cas("l")), longPress: [], flex: 1),
            KeyItem(title: "'", key: .char("'"), longPress: [], flex: 1),
        ]
        let r3: [KeyItem] = [
            KeyItem(title: "⇧", key: .shift, longPress: [], flex: 1.3),
            KeyItem(title: cas("z"), key: .char(cas("z")), longPress: ["zh"], flex: 1),
            KeyItem(title: cas("x"), key: .char(cas("x")), longPress: [], flex: 1),
            KeyItem(title: cas("c"), key: .char(cas("c")), longPress: ["ch"], flex: 1),
            KeyItem(title: cas("v"), key: .char(cas("v")), longPress: [], flex: 1),
            KeyItem(title: cas("b"), key: .char(cas("b")), longPress: [], flex: 1),
            KeyItem(title: cas("n"), key: .char(cas("n")), longPress: ["ng"], flex: 1),
            KeyItem(title: cas("m"), key: .char(cas("m")), longPress: [], flex: 1),
            KeyItem(title: "⌫", key: .backspace, longPress: [], flex: 1.3),
        ]
        let r4: [KeyItem] = [
            KeyItem(title: "123", key: .symbols, longPress: [], flex: 1.2),
            KeyItem(title: "🌐", key: .nextKeyboard, longPress: [], flex: 1.1),
            KeyItem(title: "ëöü", key: .uly, longPress: [], flex: 1.2),
            KeyItem(title: "boshluq", key: .space, longPress: [], flex: 4),
            KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.4),
        ]
        return [r1, r2, r3, r4]
    }

    private func symbolRows() -> [[KeyItem]] {
        [
            "1234567890".map { KeyItem(title: String($0), key: .char(String($0)), longPress: [], flex: 1) },
            "-/:;()$&@\"".map { KeyItem(title: String($0), key: .char(String($0)), longPress: [], flex: 1) },
            [
                KeyItem(title: "ABC", key: .letters, longPress: [], flex: 1.4),
                KeyItem(title: ".", key: .char("."), longPress: [], flex: 1),
                KeyItem(title: ",", key: .char(","), longPress: [], flex: 1),
                KeyItem(title: "?", key: .char("?"), longPress: [], flex: 1),
                KeyItem(title: "!", key: .char("!"), longPress: [], flex: 1),
                KeyItem(title: "'", key: .char("'"), longPress: [], flex: 1),
                KeyItem(title: "⌫", key: .backspace, longPress: [], flex: 1.4),
            ],
            [
                KeyItem(title: "ABC", key: .letters, longPress: [], flex: 1.4),
                KeyItem(title: "🌐", key: .nextKeyboard, longPress: [], flex: 1.1),
                KeyItem(title: "boshluq", key: .space, longPress: [], flex: 4),
                KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.4),
            ],
        ]
    }

    private func ulyRows() -> [[KeyItem]] {
        [
            ["ë", "ö", "ü", "Ë", "Ö", "Ü", "ch", "sh", "zh", "gh"].map {
                KeyItem(title: $0, key: .char($0), longPress: [], flex: 1)
            },
            [
                KeyItem(title: "ng", key: .char("ng"), longPress: [], flex: 1),
                KeyItem(title: "'", key: .char("'"), longPress: [], flex: 1),
                KeyItem(title: "-", key: .char("-"), longPress: [], flex: 1),
                KeyItem(title: ",", key: .char(","), longPress: [], flex: 1),
                KeyItem(title: ".", key: .char("."), longPress: [], flex: 1),
                KeyItem(title: "⌫", key: .backspace, longPress: [], flex: 1.3),
            ],
            [
                KeyItem(title: "ABC", key: .letters, longPress: [], flex: 1.4),
                KeyItem(title: "🌐", key: .nextKeyboard, longPress: [], flex: 1.1),
                KeyItem(title: "boshluq", key: .space, longPress: [], flex: 4),
                KeyItem(title: "return", key: .returnKey, longPress: [], flex: 1.4),
            ],
        ]
    }

    private func cas(_ s: String) -> String {
        shiftOn ? s.uppercased() : s
    }

    private func makeButton(_ item: KeyItem) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(item.title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: item.title.count > 2 ? 13 : 18, weight: .medium)
        btn.backgroundColor = isSpecial(item.key)
            ? UIColor(red: 0.77, green: 0.83, blue: 0.80, alpha: 1)
            : UIColor(red: 0.97, green: 0.99, blue: 0.98, alpha: 1)
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 8
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.2
        btn.layer.shadowOffset = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius = 0
        btn.tag = 0

        let key = item.key
        btn.addAction(UIAction { [weak self] _ in
            self?.hidePopup()
            self?.delegate?.keyboardView(self!, didTapKey: key)
        }, for: .touchUpInside)

        if !item.longPress.isEmpty {
            let long = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            long.minimumPressDuration = 0.35
            btn.addGestureRecognizer(long)
            objc_setAssociatedObject(btn, &AssociatedKeys.longPress, item.longPress, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        // Approximate wider keys via content hugging / width ratio using spacer-like transform
        btn.setContentHuggingPriority(UILayoutPriority(250 - Float(item.flex * 10)), for: .horizontal)
        return btn
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
        stack.backgroundColor = UIColor(red: 0.08, green: 0.15, blue: 0.12, alpha: 1)
        stack.layer.cornerRadius = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        stack.translatesAutoresizingMaskIntoConstraints = false
        for opt in options {
            let b = UIButton(type: .system)
            b.setTitle(opt, for: .normal)
            b.setTitleColor(.black, for: .normal)
            b.backgroundColor = .white
            b.layer.cornerRadius = 6
            b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            b.addAction(UIAction { [weak self] _ in
                self?.hidePopup()
                self?.delegate?.keyboardView(self!, didTapKey: .char(opt))
            }, for: .touchUpInside)
            stack.addArrangedSubview(b)
        }
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: btn.topAnchor, constant: -6),
        ])
        popup = stack
        longPressAnchor = btn
    }

    private func hidePopup() {
        popup?.removeFromSuperview()
        popup = nil
    }
}

private enum AssociatedKeys {
    static var longPress = "longPressOptions"
}
