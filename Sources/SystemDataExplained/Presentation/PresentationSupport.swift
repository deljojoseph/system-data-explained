import Foundation
import SwiftUI
import SDEDomain

enum ByteFormatting {
    static func string(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: max(0, bytes), countStyle: .file)
    }
}

private struct ReadingScaleKey: EnvironmentKey { static let defaultValue: Double = 1 }
extension EnvironmentValues {
    var readingScale: Double {
        get { self[ReadingScaleKey.self] }
        set { self[ReadingScaleKey.self] = newValue }
    }
}

private struct ReadingFont: ViewModifier {
    @Environment(\.readingScale) private var scale
    let size: Double
    let weight: Font.Weight
    let design: Font.Design
    func body(content: Content) -> some View {
        content.font(.system(size: size * scale, weight: weight, design: design))
    }
}

extension View {
    func sdeFont(_ size: Double, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ReadingFont(size: size, weight: weight, design: design))
    }
}

extension Color {
    static let sdeBlue = Color(nsColor: .systemBlue)
    static let sdeInk = Color(nsColor: .labelColor)
    static let sdeMuted = Color(nsColor: .secondaryLabelColor)
}

extension StorageCategory {
    var tint: Color {
        .sdeBlue
    }
}

extension ExplanationLevel {
    var tint: Color {
        .sdeBlue
    }
}

extension RiskLevel {
    var tint: Color {
        .sdeBlue
    }
}
