import UIKit
import UyghurLatinKit

final class KeyboardViewController: UIInputViewController {
    private var engine: SuggestionEngine?
    private var keyboardView: KeyboardView!
    private var heightConstraint: NSLayoutConstraint?
    private var shiftOn = false
    private var layer: KeyboardView.Layer = .letters

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.16, green: 0.25, blue: 0.22, alpha: 1)

        keyboardView = KeyboardView(frame: .zero)
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.delegate = self
        view.addSubview(keyboardView)

        let height = view.heightAnchor.constraint(equalToConstant: 280)
        height.priority = .defaultHigh
        heightConstraint = height

        NSLayoutConstraint.activate([
            height,
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        loadEngine()
        refreshSuggestions()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refreshSuggestions()
    }

    private func loadEngine() {
        do {
            let store = try LexiconStore(bundle: .main)
            engine = SuggestionEngine(store: store)
            keyboardView.setStatus("\(store.meta.wordCount) söz · offline")
        } catch {
            keyboardView.setStatus("Lexicon load failed")
        }
    }

    private func context() -> (partial: String, previous: String?) {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        var i = before.endIndex
        while i > before.startIndex {
            let prev = before.index(before: i)
            let ch = before[prev]
            if !ULYNormalizer.isWordCharacter(ch.unicodeScalars.first!) { break }
            i = prev
        }
        let partial = String(before[i...])

        var j = i
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
        let previous = k < j ? ULYNormalizer.lookupKey(String(before[k..<j])) : nil
        return (partial, previous)
    }

    private func refreshSuggestions() {
        guard let engine else {
            keyboardView.updateCandidates([], misspelled: false)
            return
        }
        let ctx = context()
        let result = engine.suggest(partial: ctx.partial, previousWord: ctx.previous, limit: 8)
        keyboardView.updateCandidates(result.candidates, misspelled: result.isMisspelled)
    }

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
        if shiftOn && text.count == 1 {
            shiftOn = false
            keyboardView.setShift(false)
        }
        refreshSuggestions()
    }

    private func deleteBackward() {
        textDocumentProxy.deleteBackward()
        refreshSuggestions()
    }

    private func applyCandidate(_ word: String) {
        let ctx = context()
        for _ in 0..<ctx.partial.count {
            textDocumentProxy.deleteBackward()
        }
        if ctx.partial.isEmpty {
            textDocumentProxy.insertText(word + " ")
        } else {
            textDocumentProxy.insertText(word + " ")
        }
        engine?.learnSelection(word)
        refreshSuggestions()
    }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardView(_ view: KeyboardView, didTapKey key: KeyboardView.Key) {
        switch key {
        case .char(let s):
            insert(s)
        case .backspace:
            deleteBackward()
        case .space:
            insert(" ")
        case .returnKey:
            insert("\n")
        case .shift:
            shiftOn.toggle()
            keyboardView.setShift(shiftOn)
        case .symbols:
            layer = .symbols
            keyboardView.setLayer(.symbols)
        case .uly:
            layer = .uly
            keyboardView.setLayer(.uly)
        case .letters:
            layer = .letters
            keyboardView.setLayer(.letters)
        case .nextKeyboard:
            advanceToNextInputMode()
        }
    }

    func keyboardView(_ view: KeyboardView, didSelectCandidate word: String) {
        applyCandidate(word)
    }
}
