import SwiftUI
import UIKit

/// Interactive keyboard-height control for the host app.
/// Drag the preview up/down to set a custom scale (not used while typing in other apps).
struct KeyboardHeightAdjustView: View {
    @Binding var scale: CGFloat
    var theme: KeyboardThemePreference

    @EnvironmentObject private var language: LanguageStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var dragBase: CGFloat?

    private var percent: Int { Int((scale * 100).rounded()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(language.string("height_label"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(percent)%")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))

                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.and.down")
                            .font(.caption.weight(.semibold))
                        Text(language.string("height_drag_hint"))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)

                    Spacer(minLength: 0)

                    KeyboardPreviewChrome(scale: scale, theme: theme)
                        .frame(height: previewHeight)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    if dragBase == nil { dragBase = scale }
                                    let delta = -value.translation.height / 200
                                    let next = KeyboardPreferences.clampScale((dragBase ?? scale) + delta)
                                    if abs(next - scale) > 0.001 {
                                        scale = next
                                    }
                                }
                                .onEnded { _ in
                                    dragBase = nil
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                        )
                }
            }
            .frame(height: 228)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(language.string("height_label"))
            .accessibilityValue("\(percent)%")
            .accessibilityAdjustableAction { direction in
                let step: CGFloat = 0.03
                switch direction {
                case .increment:
                    scale = KeyboardPreferences.clampScale(scale + step)
                case .decrement:
                    scale = KeyboardPreferences.clampScale(scale - step)
                @unknown default:
                    break
                }
            }

            HStack(spacing: 8) {
                ForEach(KeyboardHeightPreference.allCases) { preset in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = preset.scale
                        }
                        dragBase = nil
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(presetLabel(preset))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(isNear(preset) ? Color.accentColor.opacity(0.18) : Color(.tertiarySystemFill))
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 4)
    }

    private var previewHeight: CGFloat {
        (120 * scale).rounded()
    }

    private func isNear(_ preset: KeyboardHeightPreference) -> Bool {
        abs(scale - preset.scale) < 0.04
    }

    private func presetLabel(_ preset: KeyboardHeightPreference) -> String {
        switch preset {
        case .compact: return language.string("height_compact")
        case .regular: return language.string("height_regular")
        case .tall: return language.string("height_tall")
        }
    }
}

/// Lightweight visual that mirrors the stock keyboard proportions.
private struct KeyboardPreviewChrome: View {
    let scale: CGFloat
    let theme: KeyboardThemePreference
    @Environment(\.colorScheme) private var colorScheme

    private var style: UIUserInterfaceStyle {
        theme.resolvedStyle(
            for: UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        )
    }

    private var palette: KeyboardPalette {
        KeyboardPalette.palette(style: style)
    }

    var body: some View {
        let bg = Color(palette.background)
        let face = Color(palette.keyFace)
        let special = Color(palette.keySpecial)

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { idx in
                    if idx > 0 {
                        Rectangle()
                            .fill(Color(palette.separator))
                            .frame(width: 1 / UIScreen.main.scale, height: 14)
                    }
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .overlay(
                            Capsule().fill(Color(palette.candidateText).opacity(0.18)).frame(width: 36, height: 5)
                        )
                        .frame(height: 22)
                }
            }
            .padding(.horizontal, 4)
            .frame(height: 26)
            .background(bg)

            Rectangle()
                .fill(Color(palette.separator))
                .frame(height: 1 / UIScreen.main.scale)

            VStack(spacing: max(3, 4 * scale)) {
                keyRow(count: 10, face: face, special: special, letter: true)
                keyRow(count: 9, face: face, special: special, letter: true, inset: true)
                keyRow(count: 9, face: face, special: special, letter: false)
                HStack(spacing: 3) {
                    key(width: 28, color: special)
                    key(width: nil, color: face).frame(maxWidth: .infinity)
                    key(width: 36, color: special)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 5)
            .frame(maxHeight: .infinity)
            .background(bg)
        }
        .background(bg)
    }

    private func keyRow(count: Int, face: Color, special: Color, letter: Bool, inset: Bool = false) -> some View {
        HStack(spacing: 3) {
            if inset { Spacer(minLength: 8) }
            ForEach(0..<count, id: \.self) { i in
                let isSpecial = !letter && (i == 0 || i == count - 1)
                key(width: nil, color: isSpecial ? special : face)
                    .frame(maxWidth: .infinity)
            }
            if inset { Spacer(minLength: 8) }
        }
    }

    private func key(width: CGFloat?, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color)
            .frame(width: width)
            .frame(maxHeight: .infinity)
            .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 0.5)
    }
}
