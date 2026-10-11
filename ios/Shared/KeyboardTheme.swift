import UIKit

/// Colors matched to the stock iOS keyboard (light / dark).
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
            // Stock dark keyboard (~iOS 16–18)
            return KeyboardPalette(
                background: UIColor(red: 0.169, green: 0.169, blue: 0.180, alpha: 1),
                candidateBar: UIColor(red: 0.169, green: 0.169, blue: 0.180, alpha: 1),
                candidateText: UIColor(white: 0.95, alpha: 1),
                candidateSecondary: UIColor(white: 0.70, alpha: 1),
                separator: UIColor(white: 1, alpha: 0.18),
                keyFace: UIColor(red: 0.42, green: 0.42, blue: 0.44, alpha: 1),
                keySpecial: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1),
                keyText: .white,
                keyShadow: UIColor(white: 0, alpha: 0.55),
                popupBackground: UIColor(red: 0.30, green: 0.30, blue: 0.32, alpha: 1),
                misspelled: UIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: 1)
            )
        }
        // Stock light keyboard
        return KeyboardPalette(
            background: UIColor(red: 0.82, green: 0.835, blue: 0.86, alpha: 1),
            candidateBar: UIColor(red: 0.82, green: 0.835, blue: 0.86, alpha: 1),
            candidateText: UIColor(white: 0.05, alpha: 1),
            candidateSecondary: UIColor(white: 0.32, alpha: 1),
            separator: UIColor(white: 0, alpha: 0.16),
            keyFace: .white,
            keySpecial: UIColor(red: 0.675, green: 0.696, blue: 0.735, alpha: 1),
            keyText: .black,
            keyShadow: UIColor(white: 0.35, alpha: 0.35),
            popupBackground: UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1),
            misspelled: UIColor(red: 0.85, green: 0.40, blue: 0.10, alpha: 1)
        )
    }
}
