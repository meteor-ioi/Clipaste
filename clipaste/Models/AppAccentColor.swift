import SwiftUI

enum AppAccentColor: String, CaseIterable, Identifiable {
    case purple
    case blue
    case indigo
    case brown
    case cyan
    case teal
    case orange
    case pink
    case red
    case gray

    var id: String { rawValue }

    static let defaultValue: AppAccentColor = .blue

    var color: Color {
        switch self {
        case .purple:
            Color(.sRGB, red: 0.49, green: 0.34, blue: 0.91, opacity: 1)
        case .blue:
            Color(.sRGB, red: 0.30, green: 0.50, blue: 0.91, opacity: 1)
        case .indigo:
            Color(.sRGB, red: 0.25, green: 0.40, blue: 0.84, opacity: 1)
        case .brown:
            Color(.sRGB, red: 0.70, green: 0.53, blue: 0.32, opacity: 1)
        case .cyan:
            Color(.sRGB, red: 0.25, green: 0.74, blue: 0.85, opacity: 1)
        case .teal:
            Color(.sRGB, red: 0.16, green: 0.62, blue: 0.56, opacity: 1)
        case .orange:
            Color(.sRGB, red: 0.98, green: 0.53, blue: 0.12, opacity: 1)
        case .pink:
            Color(.sRGB, red: 0.91, green: 0.35, blue: 0.58, opacity: 1)
        case .red:
            Color(.sRGB, red: 0.96, green: 0.36, blue: 0.43, opacity: 1)
        case .gray:
            Color(.sRGB, red: 0.55, green: 0.51, blue: 0.46, opacity: 1)
        }
    }

    var selectedContentColor: Color {
        .white
    }

    var localizedName: LocalizedStringResource {
        switch self {
        case .purple:
            LocalizedStringResource("Purple")
        case .blue:
            LocalizedStringResource("Blue")
        case .indigo:
            LocalizedStringResource("Indigo")
        case .brown:
            LocalizedStringResource("Brown")
        case .cyan:
            LocalizedStringResource("Cyan")
        case .teal:
            LocalizedStringResource("Teal")
        case .orange:
            LocalizedStringResource("Orange")
        case .pink:
            LocalizedStringResource("Pink")
        case .red:
            LocalizedStringResource("Red")
        case .gray:
            LocalizedStringResource("Gray")
        }
    }
}
