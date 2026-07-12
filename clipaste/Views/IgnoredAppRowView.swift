import SwiftUI

struct IgnoredAppRowView: View {
    let ignoredApp: IgnoredAppItem
    let isSelected: Bool
    let accentColor: AppAccentColor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: ignoredApp.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 28, height: 28)
                .clipShape(.rect(cornerRadius: 7))

            Text(ignoredApp.displayName)
                .font(.body)
                .foregroundStyle(isSelected ? accentColor.selectedContentColor : .primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(selectionBackground)
    }
}

private extension IgnoredAppRowView {
    var selectionBackground: some View {
        RoundedRectangle(cornerRadius: 0, style: .continuous)
            .fill(isSelected ? SettingsPalette.sidebarSelectionFill(accentColor, for: colorScheme) : Color.clear)
    }
}
