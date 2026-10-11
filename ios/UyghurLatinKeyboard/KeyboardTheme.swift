import UIKit

/// Colors matched to the stock iOS keyboard (approximate system QuickType look).
struct KeyboardPalette {
    let background: UIColor
    let candidateBar: UIColor
    let candidateText: UIColor
    let candidateSecondary: UIColor
    let separator: UIColor
    let keyFace: UIColor
    let keySpecial: UIColor
    let keyText: UIColor
    let keyShadow: UIColor
    let popupBackground: UIColor
    let misspelled: UIColor

    static func palette(style: UIUserInterfaceStyle) -> KeyboardPalette {
        if style == .dark {
            return KeyboardPalette(
                background: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1),
                candidateBar: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1),
                candidateText: UIColor(white: 0.96, alpha: 1),
                candidateSecondary: UIColor(white: 0.72, alpha: 1),
                separator: UIColor(white: 1, alpha: 0.22),
                keyFace: UIColor(red: 0.38, green: 0.38, blue: 0.40, alpha: 1),
                keySpecial: UIColor(red: 0.27, green: 0.27, blue: 0.29, alpha: 1),
                keyText: .white,
                keyShadow: UIColor(white: 0, alpha: 0.45),
                popupBackground: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1),
                misspelled: UIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: 1)
            )
        }
        return KeyboardPalette(
            background: UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1),
            candidateBar: UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1),
            candidateText: UIColor(white: 0.08, alpha: 1),
            candidateSecondary: UIColor(white: 0.28, alpha: 1),
            separator: UIColor(white: 0, alpha: 0.18),
            keyFace: .white,
            keySpecial: UIColor(red: 0.68, green: 0.70, blue: 0.74, alpha: 1),
            keyText: .black,
            keyShadow: UIColor(white: 0, alpha: 0.28),
            popupBackground: UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1),
            misspelled: UIColor(red: 0.85, green: 0.40, blue: 0.10, alpha: 1)
        )
    }
}
