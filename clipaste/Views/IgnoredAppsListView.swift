import SwiftUI

struct IgnoredAppsListView: View {
    let ignoredApps: [IgnoredAppItem]
    @Binding var selection: Set<String>
    @AppStorage("appAccentColor") private var appAccentColor: AppAccentColor = .defaultValue
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectionAnchor: String?

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(ignoredApps.enumerated()), id: \.element.bundleIdentifier) { index, ignoredApp in
                            IgnoredAppRowView(
                                ignoredApp: ignoredApp,
                                isSelected: selection.contains(ignoredApp.bundleIdentifier),
                                accentColor: appAccentColor
                            )
                            .frame(width: proxy.size.width, alignment: .leading)
                            .contentShape(.rect)
                            .onTapGesture {
                                updateSelection(for: ignoredApp.bundleIdentifier, at: index)
                            }

                            if index < ignoredApps.count - 1 {
                                Divider()
                                    .overlay(separatorColor)
                                    .padding(.leading, 72)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentMargins(.zero)
                .frame(width: proxy.size.width, alignment: .leading)
            }
            .scrollIndicators(.hidden)

            if ignoredApps.isEmpty {
                IgnoredAppsEmptyStateView()
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private extension IgnoredAppsListView {
    var separatorColor: Color {
        colorScheme == .dark ? .white.opacity(0.10) : .black.opacity(0.08)
    }

    func updateSelection(for bundleIdentifier: String, at index: Int) {
        let modifierFlags = NSApp.currentEvent?.modifierFlags ?? []

        if modifierFlags.contains(.shift),
           let anchor = selectionAnchor,
           let anchorIndex = ignoredApps.firstIndex(where: { $0.bundleIdentifier == anchor }) {
            let lowerBound = min(anchorIndex, index)
            let upperBound = max(anchorIndex, index)
            selection = Set(ignoredApps[lowerBound...upperBound].map(\.bundleIdentifier))
            return
        }

        if modifierFlags.contains(.command) {
            if selection.contains(bundleIdentifier) {
                selection.remove(bundleIdentifier)
            } else {
                selection.insert(bundleIdentifier)
            }
            selectionAnchor = bundleIdentifier
            return
        }

        selection = [bundleIdentifier]
        selectionAnchor = bundleIdentifier
    }
}
