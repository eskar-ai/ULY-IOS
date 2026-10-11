import UIKit

/// Colors matched to the stock iOS 26 keyboard (light / dark).
///
/// Inside the keyboard extension the chrome is transparent so the system keyboard material
/// (and its rounded top corners) shows through exactly; `background` is only used where an
/// opaque approximation is needed (host-app preview).
struct KeyboardPalette {
    let background: UIColor
    let candidateBar: UIColor
    let candidateText: UIColor
    let candidateSecondary: UIColor
    let separator: UIColor
    let keyFace: UIColor
    /// iOS 26 draws function keys (shift, delete, 123, space) in the same color as letters.
    let keySpecial: UIColor
    let keyPressed: UIColor
    let keyText: UIColor
    let keyShadow: UIColor
    let returnDisabled: UIColor
    let returnDisabledText: UIColor
    let spaceTag: UIColor
    let popupBackground: UIColor
    let misspelled: UIColor

    static func palette(style: UIUserInterfaceStyle) -> KeyboardPalette {
        if style == .dark {
            // Sampled from an iOS 26 dark keyboard screenshot.
            let key = UIColor(white: 70 / 255, alpha: 1)
            return KeyboardPalette(
                background: UIColor(white: 34 / 255, alpha: 1),
                candidateBar: .clear,
                candidateText: UIColor(white: 160 / 255, alpha: 1),
                candidateSecondary: UIColor(white: 0.5, alpha: 1),
                separator: UIColor(white: 1, alpha: 0.08),
                keyFace: key,
                keySpecial: key,
                keyPressed: UIColor(white: 110 / 255, alpha: 1),
                keyText: .white,
                keyShadow: .clear,
                returnDisabled: UIColor(white: 121 / 255, alpha: 1),
                returnDisabledText: UIColor(white: 1, alpha: 0.35),
                spaceTag: UIColor(white: 1, alpha: 0.4),
                popupBackground: UIColor(white: 90 / 255, alpha: 1),
                misspelled: UIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: 1)
            )
        }
        return KeyboardPalette(
            background: UIColor(red: 0.82, green: 0.835, blue: 0.86, alpha: 1),
            candidateBar: .clear,
            candidateText: UIColor(white: 0.30, alpha: 1),
            candidateSecondary: UIColor(white: 0.45, alpha: 1),
            separator: UIColor(white: 0, alpha: 0.10),
            keyFace: .white,
            keySpecial: .white,
            keyPressed: UIColor(white: 0.82, alpha: 1),
            keyText: .black,
            keyShadow: .clear,
            returnDisabled: UIColor(white: 0.74, alpha: 1),
            returnDisabledText: UIColor(white: 0, alpha: 0.3),
            spaceTag: UIColor(white: 0, alpha: 0.35),
            popupBackground: UIColor(white: 0.98, alpha: 1),
            misspelled: UIColor(red: 0.85, green: 0.40, blue: 0.10, alpha: 1)
        )
    }
}
