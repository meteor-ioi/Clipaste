import SwiftUI

struct ThemeColorPicker: View {
    @Binding var selection: AppAccentColor

    var body: some View {
        LabeledContent {
            HStack(spacing: 10) {
                ForEach(AppAccentColor.allCases) { accentColor in
                    ThemeColorSwatchButton(
                        accentColor: accentColor,
                        isSelected: selection == accentColor
                    ) {
                        selection = accentColor
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } label: {
            Text("Theme Color")
        }
    }
}

private struct ThemeColorSwatchButton: View {
    let accentColor: AppAccentColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(accentColor.color)
                .frame(width: 24, height: 24)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accentColor.selectedContentColor)
                    }
                }
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.72), lineWidth: isSelected ? 1.5 : 0)
                }
                .shadow(color: isSelected ? accentColor.color.opacity(0.28) : .clear, radius: 5, y: 2)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accentColor.localizedName))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection = AppAccentColor.defaultValue

    Form {
        ThemeColorPicker(selection: $selection)
    }
    .formStyle(.grouped)
    .frame(width: 520)
}
